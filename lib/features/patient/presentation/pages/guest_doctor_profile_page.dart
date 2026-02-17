import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';
import 'package:dbs/features/doctor/domain/entities/doctor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuestDoctorProfileArgs {
  final String doctorId;
  final Map<String, dynamic>? initialData;

  const GuestDoctorProfileArgs({required this.doctorId, this.initialData});
}

class GuestDoctorProfilePage extends StatelessWidget {
  final GuestDoctorProfileArgs args;

  const GuestDoctorProfilePage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .doc(args.doctorId)
                .snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() ?? args.initialData;

              if (snapshot.connectionState == ConnectionState.waiting &&
                  data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError && data == null) {
                return _InfoMessage(
                  message: 'Unable to load doctor profile at the moment.',
                );
              }

              if (data == null) {
                return _InfoMessage(
                  message: 'Doctor profile is not available.',
                );
              }

              return _DoctorProfileContent(doctorId: args.doctorId, data: data);
            },
          ),
        ),
      ),
    );
  }
}

class _DoctorProfileContent extends StatelessWidget {
  final String doctorId;
  final Map<String, dynamic> data;

  const _DoctorProfileContent({required this.doctorId, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    final name = (data['name'] as String?)?.trim();
    final specialty = (data['specialty'] as String?)?.trim();
    final bio = (data['bio'] as String?)?.trim();
    final imageUrl = (data['profileImageUrl'] as String?)?.trim();
    final location = _readLocation(data);
    final years = _readExperienceYears(data);
    final fee = _readConsultationFee(data);
    final rating = _readRating(data);
    final credentials = _readCredentialItems(data);

    final resolvedName = (name == null || name.isEmpty) ? 'Doctor' : name;
    final resolvedSpecialty = (specialty == null || specialty.isEmpty)
        ? 'General Practice'
        : specialty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            delay: const Duration(milliseconds: 40),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundImage:
                            (imageUrl != null && imageUrl.isNotEmpty)
                            ? NetworkImage(imageUrl)
                            : null,
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? const Icon(Icons.medical_services_outlined)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resolvedName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              resolvedSpecialty,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.74,
                                ),
                              ),
                            ),
                            if (location.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                location,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.62,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (years != null)
                        _MetricPill(
                          icon: Icons.work_outline,
                          label: '$years years experience',
                        ),
                      if (fee != null)
                        _MetricPill(
                          icon: Icons.payments_outlined,
                          label: 'Consultation fee: $fee',
                        ),
                      if (rating != null)
                        _MetricPill(
                          icon: Icons.star_outline,
                          label: 'Rating: $rating',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            delay: const Duration(milliseconds: 90),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Professional summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (bio == null || bio.isEmpty)
                        ? 'Professional bio will be shared by the clinic or doctor profile team.'
                        : bio,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.35,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            delay: const Duration(milliseconds: 120),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credentials',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (credentials.isEmpty)
                    Text(
                      'Credentials will be visible once profile verification is completed.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.74,
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: credentials
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.verified_outlined,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            delay: const Duration(milliseconds: 150),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Availability preview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<_SlotPreview>>(
                    future: _loadUpcomingSlots(doctorId),
                    builder: (context, slotSnap) {
                      if (slotSnap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        );
                      }
                      final slots = slotSnap.data ?? const <_SlotPreview>[];
                      if (slots.isEmpty) {
                        return Text(
                          'No upcoming availability has been published yet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: slots
                            .map(
                              (slot) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_outlined,
                                      size: 18,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${_formatDate(slot.start)}  ${_formatTime(slot.start)} - ${_formatTime(slot.end)}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            delay: const Duration(milliseconds: 180),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.local_hospital_outlined,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'For urgent medical emergencies, contact local emergency services immediately. This platform is not an emergency-response channel.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.78,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_outlined),
                        label: const Text('Back to doctors'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (user == null) {
                            Navigator.pushNamed(context, Routes.login);
                            return;
                          }
                          Navigator.pushNamed(
                            context,
                            Routes.bookingAppointment,
                            arguments: DoctorEntity(
                              id: doctorId,
                              name: resolvedName,
                              specialty: resolvedSpecialty,
                            ),
                          );
                        },
                        icon: Icon(
                          user == null
                              ? Icons.login_outlined
                              : Icons.calendar_month_outlined,
                        ),
                        label: Text(
                          user == null ? 'Login to Book' : 'Book Appointment',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _readCredentialItems(Map<String, dynamic> data) {
    final items = <String>[];

    final qualifications = data['qualifications'];
    if (qualifications is List) {
      for (final item in qualifications) {
        final value = '$item'.trim();
        if (value.isNotEmpty) {
          items.add(value);
        }
      }
    }

    final credentials = data['credentials'];
    if (credentials is List) {
      for (final item in credentials) {
        final value = '$item'.trim();
        if (value.isNotEmpty) {
          items.add(value);
        }
      }
    }

    final license = (data['licenseNumber'] as String?)?.trim();
    if (license != null && license.isNotEmpty) {
      items.add('License: $license');
    }

    final education = (data['education'] as String?)?.trim();
    if (education != null && education.isNotEmpty) {
      items.add('Education: $education');
    }

    return items.toSet().toList();
  }

  String _readLocation(Map<String, dynamic> data) {
    const keys = ['location', 'city', 'state', 'region', 'address'];
    for (final key in keys) {
      final value = (data[key] as String?)?.trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  int? _readExperienceYears(Map<String, dynamic> data) {
    final raw = data['experienceYears'];
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  String? _readConsultationFee(Map<String, dynamic> data) {
    final raw = data['consultationFee'];
    if (raw == null) {
      return null;
    }
    final value = '$raw'.trim();
    if (value.isEmpty) {
      return null;
    }
    return value;
  }

  String? _readRating(Map<String, dynamic> data) {
    final raw = data['rating'];
    if (raw is num) {
      return raw.toStringAsFixed(1);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return null;
  }

  Future<List<_SlotPreview>> _loadUpcomingSlots(String doctorId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('availability')
          .doc(doctorId)
          .collection('slots')
          .where('isBooked', isEqualTo: false)
          .where('startTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('startTime')
          .limit(6)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        final start = _toDate(data['startTime']);
        final end = _toDate(data['endTime']);
        return _SlotPreview(start: start, end: end);
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  DateTime _toDate(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    return DateTime.now();
  }

  String _formatDate(DateTime dt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
    final weekday = weekdays[(dt.weekday - 1).clamp(0, 6)];
    final month = months[(dt.month - 1).clamp(0, 11)];
    return '$weekday, $month ${dt.day}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotPreview {
  final DateTime start;
  final DateTime end;

  const _SlotPreview({required this.start, required this.end});
}

class _InfoMessage extends StatelessWidget {
  final String message;

  const _InfoMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AppCard(child: Text(message)),
    );
  }
}
