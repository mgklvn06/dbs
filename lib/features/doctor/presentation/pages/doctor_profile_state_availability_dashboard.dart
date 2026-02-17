// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_underscores, invalid_use_of_protected_member

part of 'doctor_profile_page.dart';

extension _DoctorProfilePageStateAvailabilityDashboardExt
    on _DoctorProfilePageState {
  Future<void> _saveAvailabilitySettings(
    BuildContext context,
    String doctorId,
  ) async {
    final start = _parseTimeOfDay(_availStartController.text.trim());
    final end = _parseTimeOfDay(_availEndController.text.trim());
    final duration =
        int.tryParse(_availSlotDurationController.text.trim()) ?? 0;
    if (start == null || end == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check availability times and duration.'),
        ),
      );
      return;
    }

    final settings = _AvailabilitySettings(
      workingDays: _workingDays.toList()..sort(),
      startTime: _formatTimeOfDay(start),
      endTime: _formatTimeOfDay(end),
      slotDurationMinutes: duration,
      breakStart: _availBreakStartController.text.trim().isEmpty
          ? null
          : _availBreakStartController.text.trim(),
      breakEnd: _availBreakEndController.text.trim().isEmpty
          ? null
          : _availBreakEndController.text.trim(),
      blockedDates: _parseBlockedDates(_availBlockedDatesController.text),
    );

    try {
      await FirebaseFirestore.instance.collection('doctors').doc(doctorId).set({
        'availabilitySettings': settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Availability saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save availability: $e')),
      );
    }
  }

  void _loadAvailabilitySettings(Map<String, dynamic>? data) {
    if (_availabilityLoaded || data == null) return;
    final raw = data['availabilitySettings'];
    if (raw is Map<String, dynamic>) {
      final settings = _AvailabilitySettings.fromMap(raw);
      _workingDays
        ..clear()
        ..addAll(settings.workingDays);
      _availStartController.text = settings.startTime;
      _availEndController.text = settings.endTime;
      _availSlotDurationController.text = settings.slotDurationMinutes
          .toString();
      _availBreakStartController.text = settings.breakStart ?? '';
      _availBreakEndController.text = settings.breakEnd ?? '';
      _availBlockedDatesController.text = settings.blockedDates.join(', ');
    }
    _availabilityLoaded = true;
  }

  Future<void> _generateSlotsForNext14Days(
    BuildContext context,
    String doctorId,
  ) async {
    if (_isGeneratingSlots) return;
    final start = _parseTimeOfDay(_availStartController.text.trim());
    final end = _parseTimeOfDay(_availEndController.text.trim());
    final duration =
        int.tryParse(_availSlotDurationController.text.trim()) ?? 0;
    final breakStart = _parseTimeOfDay(_availBreakStartController.text.trim());
    final breakEnd = _parseTimeOfDay(_availBreakEndController.text.trim());

    if (start == null || end == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check availability times and duration.'),
        ),
      );
      return;
    }

    setState(() => _isGeneratingSlots = true);

    final rangeStart = _dateOnly(DateTime.now());
    final rangeEnd = rangeStart.add(const Duration(days: 14));

    try {
      await _generateSlotsForRange(
        doctorId,
        rangeStart,
        rangeEnd,
        start,
        end,
        duration,
        breakStart,
        breakEnd,
        _parseBlockedDates(_availBlockedDatesController.text),
        _workingDays.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Slots generated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate slots: $e')));
    } finally {
      if (mounted) setState(() => _isGeneratingSlots = false);
    }
  }

  Future<void> _generateSlotsForRange(
    String doctorId,
    DateTime rangeStart,
    DateTime rangeEnd,
    TimeOfDay start,
    TimeOfDay end,
    int durationMinutes,
    TimeOfDay? breakStart,
    TimeOfDay? breakEnd,
    List<String> blockedDates,
    List<int> workingDays,
  ) async {
    final db = FirebaseFirestore.instance;
    final slotsRef = db
        .collection('availability')
        .doc(doctorId)
        .collection('slots');
    final existingSnap = await slotsRef
        .where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart),
        )
        .where('startTime', isLessThan: Timestamp.fromDate(rangeEnd))
        .get();
    final existingIds = existingSnap.docs.map((d) => d.id).toSet();

    final startMinutes = _minutesFromTime(start);
    final endMinutes = _minutesFromTime(end);
    final breakStartMinutes = breakStart == null
        ? null
        : _minutesFromTime(breakStart);
    final breakEndMinutes = breakEnd == null
        ? null
        : _minutesFromTime(breakEnd);

    var batch = db.batch();
    var ops = 0;

    for (
      var day = rangeStart;
      day.isBefore(rangeEnd);
      day = day.add(const Duration(days: 1))
    ) {
      if (!workingDays.contains(day.weekday)) continue;
      final dayKey = _formatDateKey(day);
      if (blockedDates.contains(dayKey)) continue;

      for (
        var m = startMinutes;
        m + durationMinutes <= endMinutes;
        m += durationMinutes
      ) {
        if (breakStartMinutes != null && breakEndMinutes != null) {
          final overlap =
              m < breakEndMinutes && (m + durationMinutes) > breakStartMinutes;
          if (overlap) continue;
        }
        final slotStart = DateTime(
          day.year,
          day.month,
          day.day,
        ).add(Duration(minutes: m));
        final slotEnd = slotStart.add(Duration(minutes: durationMinutes));
        final slotId =
            'slot_${_formatDateKey(day)}_${_formatTimeKey(slotStart)}';
        if (existingIds.contains(slotId)) continue;

        batch.set(slotsRef.doc(slotId), {
          'startTime': Timestamp.fromDate(slotStart),
          'endTime': Timestamp.fromDate(slotEnd),
          'isBooked': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        ops += 1;

        if (ops >= 450) {
          await batch.commit();
          batch = db.batch();
          ops = 0;
        }
      }
    }

    if (ops > 0) {
      await batch.commit();
    }
  }

  Future<void> _promptBlockTime(BuildContext context, String doctorId) async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now(),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (pickedTime == null) return;

    final durationController = TextEditingController(text: '30');
    final duration = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Block time duration (minutes)'),
          content: TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Minutes'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = int.tryParse(durationController.text.trim()) ?? 0;
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Block'),
            ),
          ],
        );
      },
    );

    durationController.dispose();
    if (duration == null || duration <= 0) return;

    final slotStart = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final slotEnd = slotStart.add(Duration(minutes: duration));
    final slotId =
        'slot_${_formatDateKey(slotStart)}_${_formatTimeKey(slotStart)}';
    final slotRef = FirebaseFirestore.instance
        .collection('availability')
        .doc(doctorId)
        .collection('slots')
        .doc(slotId);

    final existing = await slotRef.get();
    if (existing.exists) {
      final data = existing.data();
      final isBooked = (data?['isBooked'] as bool?) ?? false;
      final bookedBy = data?['bookedBy'] as String?;
      if (isBooked && bookedBy != doctorId) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slot already booked by a patient.')),
        );
        return;
      }
      await slotRef.update({
        'isBooked': true,
        'bookedBy': doctorId,
        'blockedReason': 'manual',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await slotRef.set({
        'startTime': Timestamp.fromDate(slotStart),
        'endTime': Timestamp.fromDate(slotEnd),
        'isBooked': true,
        'bookedBy': doctorId,
        'blockedReason': 'manual',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Time blocked')));
  }

  Future<_DoctorDashboardMetrics> _loadDashboardMetrics() async {
    final doctorId = _currentDoctorId();
    if (doctorId == null) {
      return const _DoctorDashboardMetrics(
        appointmentsToday: 0,
        upcomingWeek: 0,
        pendingApprovals: 0,
        availabilityActive: false,
        nextAppointments: [],
      );
    }

    final db = FirebaseFirestore.instance;
    final apptsSnap = await db
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrow = todayStart.add(const Duration(days: 1));
    final weekEnd = todayStart.add(const Duration(days: 7));

    var todayCount = 0;
    var upcomingCount = 0;
    var pendingCount = 0;
    final upcomingList = <_AppointmentPreview>[];

    for (final doc in apptsSnap.docs) {
      final data = doc.data();
      final dt = _parseDate(data['appointmentTime'] ?? data['dateTime']);
      final status = (data['status'] as String?) ?? 'pending';
      final isActive =
          status == 'pending' || status == 'confirmed' || status == 'accepted';
      if (isActive &&
          dt.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(tomorrow)) {
        todayCount += 1;
      }
      if (isActive &&
          dt.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(weekEnd)) {
        upcomingCount += 1;
      }
      if (status == 'pending') {
        pendingCount += 1;
      }
      if (isActive && dt.isAfter(now)) {
        upcomingList.add(
          _AppointmentPreview(
            id: doc.id,
            patientId: (data['userId'] as String?) ?? '',
            dateTime: dt,
            status: status,
          ),
        );
      }
    }

    upcomingList.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final nextAppointments = upcomingList.take(5).toList();

    bool availabilityActive = false;
    final slotsSnap = await db
        .collection('availability')
        .doc(doctorId)
        .collection('slots')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .limit(20)
        .get();
    for (final doc in slotsSnap.docs) {
      final data = doc.data();
      final isBooked = (data['isBooked'] as bool?) ?? false;
      if (!isBooked) {
        availabilityActive = true;
        break;
      }
    }

    return _DoctorDashboardMetrics(
      appointmentsToday: todayCount,
      upcomingWeek: upcomingCount,
      pendingApprovals: pendingCount,
      availabilityActive: availabilityActive,
      nextAppointments: nextAppointments,
    );
  }

  Future<Map<String, String>> _prefetchUserNames(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final firestore = FirebaseFirestore.instance;
    final users = <String, String>{};
    final list = ids.where((id) => id.isNotEmpty).toList();
    const chunk = 10;
    for (var i = 0; i < list.length; i += chunk) {
      final slice = list.sublist(i, min(i + chunk, list.length));
      final q = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: slice)
          .get();
      for (final doc in q.docs) {
        final data = doc.data();
        users[doc.id] =
            (data['displayName'] as String?) ??
            (data['email'] as String?) ??
            doc.id;
      }
    }
    return users;
  }

  Future<Map<String, _UserDetails>> _prefetchUserDetails(
    Set<String> ids,
  ) async {
    if (ids.isEmpty) return {};
    final firestore = FirebaseFirestore.instance;
    final users = <String, _UserDetails>{};
    final list = ids.where((id) => id.isNotEmpty).toList();
    const chunk = 10;
    for (var i = 0; i < list.length; i += chunk) {
      final slice = list.sublist(i, min(i + chunk, list.length));
      final q = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: slice)
          .get();
      for (final doc in q.docs) {
        final data = doc.data();
        final privacy = _readMap(data['privacySettings']);
        final sharePhoneWithDoctors = _readBool(
          privacy['sharePhoneWithDoctors'],
          true,
        );
        final name =
            (data['displayName'] as String?) ??
            (data['email'] as String?) ??
            doc.id;
        final email = (data['email'] as String?) ?? '';
        final phone = sharePhoneWithDoctors
            ? (data['phone'] as String?) ?? ''
            : '';
        users[doc.id] = _UserDetails(name: name, email: email, phone: phone);
      }
    }
    return users;
  }
}
