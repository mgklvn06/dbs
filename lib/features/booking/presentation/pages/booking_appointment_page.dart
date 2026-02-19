// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unnecessary_import
import 'package:firebase_core/firebase_core.dart';
import 'package:dbs/core/services/mpesa_service.dart';
import 'package:dbs/features/doctor/domain/usecases/get_doctors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:dbs/features/doctor/domain/entities/doctor.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';

import '../../presentation/bloc/booking_bloc.dart';
import '../../presentation/bloc/booking_event.dart';
import '../../presentation/bloc/booking_state.dart';

final sl = GetIt.instance;

class BookingAppointmentPage extends StatefulWidget {
  final DoctorEntity? initialDoctor;
  const BookingAppointmentPage({super.key, this.initialDoctor});

  @override
  State<BookingAppointmentPage> createState() => _BookingAppointmentPageState();
}

class _BookingAppointmentPageState extends State<BookingAppointmentPage> {
  String? _selectedDoctorId;
  String? _selectedSlotId;
  DateTime? _selectedDateTime;
  late final BookingBloc _bookingBloc;
  final MpesaService _mpesaService = MpesaService();
  final TextEditingController _mpesaPhoneController = TextEditingController();
  final TextEditingController _mpesaAmountController = TextEditingController(
    text: '1',
  );
  bool _isPaymentInProgress = false;
  bool _loadingDoctorFee = false;
  String? _doctorFeeDisplay;
  String? _feeLoadedDoctorId;
  Map<String, dynamic>? _pendingPaymentPayload;

  @override
  void initState() {
    super.initState();
    _bookingBloc = sl<BookingBloc>();
    _selectedDoctorId = widget.initialDoctor?.id;
    _prefillMpesaPhone();
    _ensureDoctorFeeLoaded(_selectedDoctorId);
  }

  @override
  void dispose() {
    _bookingBloc.close();
    _mpesaPhoneController.dispose();
    _mpesaAmountController.dispose();
    super.dispose();
  }

  Future<void> _prefillMpesaPhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final phone = _readString(snap.data()?['phone']);
      if (phone.isEmpty || _mpesaPhoneController.text.trim().isNotEmpty) {
        return;
      }
      if (!mounted) return;
      _mpesaPhoneController.text = phone;
    } catch (_) {
      // Non-blocking fallback: user can still enter phone manually.
    }
  }

  void _ensureDoctorFeeLoaded(String? doctorId) {
    final id = doctorId?.trim() ?? '';
    if (id.isEmpty || id == _feeLoadedDoctorId) return;
    _feeLoadedDoctorId = id;
    _loadDoctorFee(id);
  }

  Future<void> _loadDoctorFee(String doctorId) async {
    setState(() {
      _loadingDoctorFee = true;
      _doctorFeeDisplay = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get();
      final data = snap.data() ?? <String, dynamic>{};
      final fee = _readNum(data['consultationFee']);
      if (!mounted) return;
      if (fee != null && fee > 0) {
        final amountText = fee % 1 == 0
            ? fee.toInt().toString()
            : fee.toStringAsFixed(2);
        _mpesaAmountController.text = amountText;
        setState(() {
          _doctorFeeDisplay = 'KES $amountText';
          _loadingDoctorFee = false;
        });
        return;
      }
      setState(() {
        _doctorFeeDisplay = null;
        _loadingDoctorFee = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _doctorFeeDisplay = null;
        _loadingDoctorFee = false;
      });
    }
  }

  Future<void> _submit() async {
    final doctorId = _selectedDoctorId ?? '';
    final dt = _selectedDateTime;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (doctorId.isEmpty || dt == null || _selectedSlotId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a doctor and slot')));
      return;
    }

    final normalizedPhone = MpesaService.normalizePhone(
      _mpesaPhoneController.text.trim(),
    );
    if (normalizedPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid M-Pesa phone number (2547XXXXXXXX).'),
        ),
      );
      return;
    }

    final amount = num.tryParse(_mpesaAmountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount greater than 0.')),
      );
      return;
    }

    setState(() {
      _isPaymentInProgress = true;
      _pendingPaymentPayload = null;
    });

    try {
      final stk = await _mpesaService.initiateStkPush(
        phone: normalizedPhone,
        amount: amount,
        userId: user.uid,
        doctorId: doctorId,
        slotId: _selectedSlotId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'STK prompt sent. Enter your M-Pesa PIN on your phone to continue.',
          ),
        ),
      );

      final tx = await _waitForTransactionResult(stk.checkoutRequestId);
      if (!mounted) return;

      if (!tx.isSuccess) {
        final message = _paymentFailureMessage(tx);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      }

      final paymentPayload = <String, dynamic>{
        'method': 'mpesa',
        'status': tx.status,
        'checkoutRequestId': tx.checkoutRequestId,
        if (tx.merchantRequestId.isNotEmpty)
          'merchantRequestId': tx.merchantRequestId,
        if (tx.mpesaReceiptNumber.isNotEmpty)
          'receiptNumber': tx.mpesaReceiptNumber,
        'amount': amount,
        'phone': normalizedPhone,
        'resultCode': tx.resultCode,
        if (tx.resultDesc.isNotEmpty) 'resultDesc': tx.resultDesc,
        'paidAt': DateTime.now().toUtc().toIso8601String(),
      };

      _pendingPaymentPayload = paymentPayload;
      _bookingBloc.add(
        BookAppointmentRequested(
          userId: user.uid,
          doctorId: doctorId,
          dateTime: dt,
          slotId: _selectedSlotId,
          payment: paymentPayload,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = _friendlyPaymentError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('M-Pesa payment failed: $message')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPaymentInProgress = false;
        });
      }
    }
  }

  Future<MpesaTransactionStatus> _waitForTransactionResult(
    String checkoutRequestId,
  ) async {
    const maxAttempts = 18;
    for (var attempt = 0; attempt < maxAttempts; attempt += 1) {
      await Future.delayed(const Duration(seconds: 5));
      final tx = await _mpesaService.getTransactionStatus(checkoutRequestId);
      if (tx.isTerminal) return tx;
    }

    return MpesaTransactionStatus(
      checkoutRequestId: checkoutRequestId,
      merchantRequestId: '',
      status: 'timeout',
      resultCode: 1037,
      resultDesc: 'Timed out waiting for payment confirmation.',
      amount: null,
      phone: '',
      mpesaReceiptNumber: '',
    );
  }

  String _paymentFailureMessage(MpesaTransactionStatus tx) {
    if (tx.status == 'cancelled') {
      return 'Payment was cancelled on phone.';
    }
    if (tx.status == 'timeout') {
      return 'Payment timed out. Please try again.';
    }
    if (tx.resultDesc.isNotEmpty) {
      return 'Payment failed: ${tx.resultDesc}';
    }
    return 'Payment failed. Please try again.';
  }

  String _friendlyPaymentError(Object error) {
    final raw = '$error';
    if (raw.contains('Missing required configuration')) {
      return 'Backend is missing Daraja credentials (Consumer Key/Secret, Passkey, or Callback URL).';
    }
    if (raw.contains('Invalid configuration values')) {
      return 'Backend has placeholder/invalid Daraja values. Update .env with real credentials and HTTPS callback URL.';
    }
    if (raw.contains('Failed to obtain Daraja access token')) {
      return 'Could not get Daraja access token. Check Consumer Key and Consumer Secret.';
    }
    if (raw.contains('Cannot read properties of undefined')) {
      return 'Backend received an unexpected Daraja response. Recheck backend credentials and callback URL.';
    }
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final settingsRef = FirebaseFirestore.instance
        .collection('settings')
        .doc('system');
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: settingsRef.snapshots(),
      builder: (context, settingsSnap) {
        final settings = settingsSnap.data?.data() ?? {};
        final maintenance = _readMap(settings['maintenance']);
        final booking = _readMap(settings['booking']);
        final maintenanceMode = _readBool(
          maintenance['enabled'],
          _readBool(settings['maintenanceMode'], false),
        );
        final bookingEnabled = _readBool(booking['enabled'], true);
        final bookingDisabled = maintenanceMode || !bookingEnabled;
        final maintenanceMessage = (maintenance['message'] as String?)?.trim();
        final disabledMessage =
            (maintenanceMessage != null && maintenanceMessage.isNotEmpty)
            ? maintenanceMessage
            : 'Booking is temporarily disabled by the admin.';

        return BlocProvider<BookingBloc>.value(
          value: _bookingBloc,
          child: Scaffold(
            appBar: AppBar(title: const Text('Select a slot')),
            body: AppBackground(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (bookingDisabled)
                      AppCard(
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(disabledMessage)),
                          ],
                        ),
                      ),
                    if (bookingDisabled) const SizedBox(height: 12),
                    Reveal(
                      delay: const Duration(milliseconds: 50),
                      child: const Text(
                        'Choose an available slot',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Reveal(
                      delay: const Duration(milliseconds: 110),
                      child: AppCard(
                        child: FutureBuilder<List<DoctorEntity>>(
                          future: sl<GetDoctors>()(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Text(
                                'Failed to load doctors: ${snapshot.error}',
                              );
                            }
                            final doctors = (snapshot.data ?? [])
                                .where((d) => (d.id ?? '').isNotEmpty)
                                .toList();
                            if (doctors.isEmpty) {
                              return const Text('No doctors available');
                            }

                            final selectedId =
                                _selectedDoctorId ?? doctors.first.id;
                            final selected = doctors.firstWhere(
                              (d) => d.id == selectedId,
                              orElse: () => doctors.first,
                            );
                            _selectedDoctorId = selected.id;
                            _ensureDoctorFeeLoaded(_selectedDoctorId);

                            return DropdownButtonFormField<DoctorEntity>(
                              initialValue: selected,
                              items: doctors
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text('${d.name} - ${d.specialty}'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: bookingDisabled
                                  ? null
                                  : (d) {
                                      setState(() {
                                        _selectedDoctorId = d?.id;
                                        _selectedSlotId = null;
                                        _selectedDateTime = null;
                                      });
                                      _ensureDoctorFeeLoaded(d?.id);
                                    },
                              decoration: const InputDecoration(
                                labelText: 'Select doctor',
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Available slots',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _selectedDoctorId == null
                          ? const Center(
                              child: Text('Select a doctor to view slots'),
                            )
                          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('availability')
                                  .doc(_selectedDoctorId)
                                  .collection('slots')
                                  .where('isBooked', isEqualTo: false)
                                  .where(
                                    'startTime',
                                    isGreaterThan: Timestamp.fromDate(
                                      DateTime.now(),
                                    ),
                                  )
                                  .orderBy('startTime')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      _friendlyFirestoreError(snapshot.error),
                                    ),
                                  );
                                }
                                final docs = snapshot.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return const Center(
                                    child: Text('No available slots'),
                                  );
                                }

                                return ListView.separated(
                                  itemCount: docs.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final doc = docs[index];
                                    final data = doc.data();
                                    final start =
                                        (data['startTime'] as Timestamp?)
                                            ?.toDate();
                                    final end = (data['endTime'] as Timestamp?)
                                        ?.toDate();
                                    if (start == null) {
                                      return const SizedBox.shrink();
                                    }
                                    final isSelected =
                                        _selectedSlotId == doc.id;
                                    return InkWell(
                                      onTap: bookingDisabled
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedSlotId = doc.id;
                                                _selectedDateTime = start;
                                              });
                                            },
                                      borderRadius: BorderRadius.circular(18),
                                      child: AppCard(
                                        color: isSelected
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.12)
                                            : null,
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected
                                                  ? Icons.check_circle
                                                  : Icons.schedule,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _formatSlot(start, end),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Slot ID: ${doc.id}',
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(Icons.check),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'M-Pesa payment',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Backend auto-detects local URL. Keep the M-Pesa backend running.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          TextField(
                            controller: _mpesaPhoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !bookingDisabled && !_isPaymentInProgress,
                            decoration: const InputDecoration(
                              labelText: 'M-Pesa phone',
                              hintText: '2547XXXXXXXX',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _mpesaAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            enabled: !bookingDisabled && !_isPaymentInProgress,
                            decoration: const InputDecoration(
                              labelText: 'Amount (KES)',
                              hintText: '1',
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_loadingDoctorFee)
                            const Text('Loading doctor consultation fee...')
                          else if (_doctorFeeDisplay != null)
                            Text(
                              'Detected doctor consultation fee: $_doctorFeeDisplay',
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedDateTime != null
                          ? 'Selected: ${_formatSlot(_selectedDateTime!, null)}'
                          : 'No slot selected',
                    ),
                    const SizedBox(height: 12),
                    BlocConsumer<BookingBloc, BookingState>(
                      listener: (context, state) {
                        if (state is BookingCreated) {
                          _pendingPaymentPayload = null;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Appointment created and M-Pesa payment verified.',
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        } else if (state is BookingError) {
                          final receipt = _readString(
                            _pendingPaymentPayload?['receiptNumber'],
                          );
                          final suffix = receipt.isNotEmpty
                              ? ' Payment already succeeded (receipt: $receipt). Please contact support.'
                              : '';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${state.message}$suffix')),
                          );
                        }
                      },
                      builder: (context, state) {
                        final busy =
                            state is BookingLoading || _isPaymentInProgress;
                        if (busy) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return ElevatedButton(
                          onPressed: bookingDisabled ? null : _submit,
                          child: const Text(
                            'Pay with M-Pesa & Confirm booking',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Map<String, dynamic> _readMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry('$key', value));
  }
  return <String, dynamic>{};
}

String _readString(dynamic raw) {
  if (raw is String) return raw.trim();
  if (raw == null) return '';
  return '$raw'.trim();
}

num? _readNum(dynamic raw) {
  if (raw is num) return raw;
  if (raw is String) return num.tryParse(raw.trim());
  return null;
}

bool _readBool(dynamic raw, bool fallback) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}

String _formatSlot(DateTime start, DateTime? end) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String two(int n) => n.toString().padLeft(2, '0');
  final h = start.hour % 12 == 0 ? 12 : start.hour % 12;
  final ampm = start.hour >= 12 ? 'PM' : 'AM';
  final date = '${months[start.month - 1]} ${start.day}, ${start.year}';
  final time = '${two(h)}:${two(start.minute)} $ampm';
  if (end == null) return '$date | $time';
  final endH = end.hour % 12 == 0 ? 12 : end.hour % 12;
  final endAmpm = end.hour >= 12 ? 'PM' : 'AM';
  final endTime = '${two(endH)}:${two(end.minute)} $endAmpm';
  return '$date | $time - $endTime';
}

String _friendlyFirestoreError(Object? error) {
  if (error is FirebaseException) {
    if (error.code == 'failed-precondition') {
      return 'Missing index for slots query. Deploy Firestore indexes and retry.';
    }
    if (error.code == 'permission-denied') {
      return 'Permission denied. Make sure Firestore rules are deployed and you are signed in.';
    }
  }
  return 'Failed to load slots: $error';
}
