
// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';
import 'package:dbs/features/doctor/domain/entities/doctor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientLandingPage extends StatefulWidget {
  const PatientLandingPage({super.key});

  @override
  State<PatientLandingPage> createState() => _PatientLandingPageState();
}

class _PatientLandingPageState extends State<PatientLandingPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handlePrimaryCta(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, Routes.login);
    } else {
      Navigator.pushNamed(context, Routes.authRedirect);
    }
  }

  void _handleBookDoctor(BuildContext context, DoctorEntity doctor) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, Routes.login);
      return;
    }
    Navigator.pushNamed(context, Routes.bookingAppointment, arguments: doctor);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Reveal(
                  delay: const Duration(milliseconds: 40),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book Trusted Doctors Online',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure. Fast. Professional.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                          decoration: const InputDecoration(
                            hintText: 'Search by specialty or doctor name',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _handlePrimaryCta(context),
                                child: Text(user == null ? 'Book Appointment' : 'Go to dashboard'),
                              ),
                            ),
                            if (user == null) ...[
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () => Navigator.pushNamed(context, Routes.register),
                                child: const Text('Create account'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Reveal(
                  delay: const Duration(milliseconds: 100),
                  child: _FeaturedDoctorsSection(
                    query: _query,
                    onBook: (doctor) => _handleBookDoctor(context, doctor),
                  ),
                ),
                const SizedBox(height: 18),
                Reveal(
                  delay: const Duration(milliseconds: 160),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How it works',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _StepTile(
                          index: '1',
                          title: 'Choose Doctor',
                          subtitle: 'Browse specialties and profiles.',
                        ),
                        const SizedBox(height: 10),
                        _StepTile(
                          index: '2',
                          title: 'Select Time',
                          subtitle: 'Pick a slot that fits your schedule.',
                        ),
                        const SizedBox(height: 10),
                        _StepTile(
                          index: '3',
                          title: 'Attend Appointment',
                          subtitle: 'Get professional care and follow-up.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Reveal(
                  delay: const Duration(milliseconds: 220),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trusted care',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _TrustChip(label: 'Licensed Doctors', icon: Icons.verified_outlined),
                            _TrustChip(label: 'Secure Booking', icon: Icons.lock_outline),
                            _TrustChip(label: 'Encrypted Data', icon: Icons.shield_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Support: support@astracare.com',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Privacy Policy | Terms | Help Center',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _FeaturedDoctorsSection extends StatelessWidget {
  final String query;
  final void Function(DoctorEntity doctor) onBook;

  const _FeaturedDoctorsSection({
    required this.query,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured doctors',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .where('isActive', isEqualTo: true)
                .limit(6)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Text('Failed to load doctors');
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text('No doctors available');
              }

              final normalized = query.trim().toLowerCase();
              final filtered = normalized.isEmpty
                  ? docs
                  : docs.where((doc) {
                      final data = doc.data();
                      final name = (data['name'] as String?) ?? '';
                      final specialty = (data['specialty'] as String?) ?? '';
                      return name.toLowerCase().contains(normalized) ||
                          specialty.toLowerCase().contains(normalized);
                    }).toList();

              if (filtered.isEmpty) {
                return const Text('No matching doctors');
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final itemWidth = width < 520 ? width : (width - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: filtered.map((doc) {
                      final data = doc.data();
                      final name = (data['name'] as String?) ?? 'Doctor';
                      final specialty = (data['specialty'] as String?) ?? 'Specialist';
                      final imageUrl = data['profileImageUrl'] as String?;
                      final rating = data['rating'];
                      final ratingText = rating is num ? rating.toStringAsFixed(1) : null;
                      final doctor = DoctorEntity(id: doc.id, name: name, specialty: specialty);
                      return SizedBox(
                        width: itemWidth,
                        child: AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                                        ? NetworkImage(imageUrl)
                                        : null,
                                    child: imageUrl == null || imageUrl.isEmpty
                                        ? const Icon(Icons.medical_services_outlined)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          specialty,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (ratingText != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        ratingText,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => onBook(doctor),
                                child: const Text('Book'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String index;
  final String title;
  final String subtitle;

  const _StepTile({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              index,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _TrustChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
