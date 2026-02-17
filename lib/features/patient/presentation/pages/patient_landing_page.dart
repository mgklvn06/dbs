import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';
import 'package:dbs/features/patient/presentation/pages/guest_doctor_profile_page.dart';
import 'package:dbs/features/patient/presentation/pages/guest_doctors_page.dart';
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

  void _openBrowseDoctors({String? query}) {
    Navigator.pushNamed(
      context,
      Routes.guestDoctors,
      arguments: GuestDoctorsPageArgs(initialQuery: (query ?? _query).trim()),
    );
  }

  void _openDoctorProfile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    Navigator.pushNamed(
      context,
      Routes.guestDoctorProfile,
      arguments: GuestDoctorProfileArgs(
        doctorId: doc.id,
        initialData: doc.data(),
      ),
    );
  }

  void _handleBookAppointment() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, Routes.login);
      return;
    }
    Navigator.pushNamed(context, Routes.booking);
  }

  void _handleJoinAsDoctor() {
    Navigator.pushNamed(context, Routes.register);
  }

  void _showFooterInfo(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label details will be available in a dedicated page soon.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  child: _HeroSection(
                    isGuest: user == null,
                    searchController: _searchController,
                    onSearchChanged: (value) {
                      setState(() {
                        _query = value.trim();
                      });
                    },
                    onBookAppointment: _handleBookAppointment,
                    onJoinDoctor: _handleJoinAsDoctor,
                    onSignIn: () => Navigator.pushNamed(context, Routes.login),
                    onCreateAccount: () =>
                        Navigator.pushNamed(context, Routes.register),
                    onBrowseDoctors: () => _openBrowseDoctors(),
                  ),
                ),
                const SizedBox(height: 18),
                Reveal(
                  delay: const Duration(milliseconds: 100),
                  child: _HowItWorksSection(),
                ),
                const SizedBox(height: 18),
                Reveal(
                  delay: const Duration(milliseconds: 140),
                  child: _HighlightsSection(),
                ),
                const SizedBox(height: 18),
                Reveal(
                  delay: const Duration(milliseconds: 180),
                  child: _FeaturedDoctorsPreview(
                    query: _query,
                    onViewProfile: _openDoctorProfile,
                    onBrowseDoctors: () => _openBrowseDoctors(query: _query),
                  ),
                ),
                const SizedBox(height: 18),
                Reveal(
                  delay: const Duration(milliseconds: 220),
                  child: _ConversionSection(
                    onCreateAccount: () =>
                        Navigator.pushNamed(context, Routes.register),
                    onBrowseDoctors: () => _openBrowseDoctors(query: _query),
                  ),
                ),
                const SizedBox(height: 18),
                _LandingFooter(
                  onAbout: () => _showFooterInfo('About'),
                  onPrivacy: () => _showFooterInfo('Privacy Policy'),
                  onTerms: () => _showFooterInfo('Terms'),
                  onContact: () => _showFooterInfo('Contact'),
                  onDoctorRegistration: () => _handleJoinAsDoctor(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isGuest;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBookAppointment;
  final VoidCallback onJoinDoctor;
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;
  final VoidCallback onBrowseDoctors;

  const _HeroSection({
    required this.isGuest,
    required this.searchController,
    required this.onSearchChanged,
    required this.onBookAppointment,
    required this.onJoinDoctor,
    required this.onSignIn,
    required this.onCreateAccount,
    required this.onBrowseDoctors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;

          Widget left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'AstraCare',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Book Trusted Doctors Anytime, Anywhere',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search verified doctors, compare specialties, and plan consultations from a secure healthcare platform.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.34,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: onBookAppointment,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Book Appointment'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onJoinDoctor,
                    icon: const Icon(Icons.medical_services_outlined),
                    label: const Text('Join as Doctor'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Quick search by doctor name or specialty',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: onBrowseDoctors,
                    icon: const Icon(Icons.arrow_forward_outlined),
                    tooltip: 'Browse doctors',
                  ),
                ),
              ),
              if (isGuest) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    TextButton.icon(
                      onPressed: onSignIn,
                      icon: const Icon(Icons.login_outlined),
                      label: const Text('Sign in'),
                    ),
                    TextButton.icon(
                      onPressed: onCreateAccount,
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Create account'),
                    ),
                    TextButton.icon(
                      onPressed: onBrowseDoctors,
                      icon: const Icon(Icons.manage_search_outlined),
                      label: const Text('Browse doctors'),
                    ),
                  ],
                ),
              ],
            ],
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                left,
                const SizedBox(height: 16),
                const _HeroPreviewPanel(),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 8, child: left),
              const SizedBox(width: 16),
              const Expanded(flex: 5, child: _HeroPreviewPanel()),
            ],
          );
        },
      ),
    );
  }
}

class _HeroPreviewPanel extends StatelessWidget {
  const _HeroPreviewPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.colorScheme.surface.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary,
                ),
                child: const Icon(Icons.favorite_outline, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Care dashboard preview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _PreviewRow(
            icon: Icons.verified_outlined,
            title: 'Verified doctor identities',
          ),
          const SizedBox(height: 8),
          const _PreviewRow(
            icon: Icons.schedule_outlined,
            title: 'Live slot visibility',
          ),
          const SizedBox(height: 8),
          const _PreviewRow(
            icon: Icons.lock_outline,
            title: 'Protected patient access',
          ),
          const SizedBox(height: 12),
          Text(
            'Clinical and scheduling details are shown clearly to keep booking decisions safe and informed.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String title;

  const _PreviewRow({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HowStepCard(
                icon: Icons.search,
                title: 'Search Doctor',
                subtitle: 'Browse specialties and doctor profiles quickly.',
              ),
              _HowStepCard(
                icon: Icons.event_available_outlined,
                title: 'Choose Time',
                subtitle: 'Select a suitable slot from available schedules.',
              ),
              _HowStepCard(
                icon: Icons.video_camera_front_outlined,
                title: 'Get Consultation',
                subtitle: 'Attend your consultation and follow-up care plan.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HowStepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HowStepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width >= 1120
        ? 300.0
        : width >= 760
        ? (width - 76) / 2
        : double.infinity;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.28),
        ),
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: theme.colorScheme.primary.withValues(alpha: 0.14),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Highlights',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HighlightCard(
                icon: Icons.verified_user_outlined,
                title: 'Verified Doctors',
                subtitle: 'Professional profiles reviewed before listing.',
              ),
              _HighlightCard(
                icon: Icons.shield_outlined,
                title: 'Secure Booking System',
                subtitle: 'Booking actions are protected with account access.',
              ),
              _HighlightCard(
                icon: Icons.update_outlined,
                title: 'Real-Time Availability',
                subtitle: 'See updated schedules and open consultation slots.',
              ),
              _HighlightCard(
                icon: Icons.swap_horiz_outlined,
                title: 'Easy Rescheduling',
                subtitle:
                    'Appointment changes are managed with clear policies.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HighlightCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width >= 1120
        ? 300.0
        : width >= 760
        ? (width - 76) / 2
        : double.infinity;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface.withValues(alpha: 0.76),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedDoctorsPreview extends StatelessWidget {
  final String query;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>> doc)
  onViewProfile;
  final VoidCallback onBrowseDoctors;

  const _FeaturedDoctorsPreview({
    required this.query,
    required this.onViewProfile,
    required this.onBrowseDoctors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Featured Doctors',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onBrowseDoctors,
                icon: const Icon(Icons.manage_search_outlined),
                label: const Text('Browse all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('doctors')
                .where('isActive', isEqualTo: true)
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text(
                  'Unable to load featured doctors right now.',
                  style: theme.textTheme.bodyMedium,
                );
              }

              final docs = (snapshot.data?.docs ?? []).where((doc) {
                return _isDoctorDiscoverable(doc.data());
              }).toList();

              if (docs.isEmpty) {
                return _PreviewEmpty(
                  message:
                      'No featured doctors are available yet. Browse the directory to explore current listings.',
                  onBrowse: onBrowseDoctors,
                );
              }

              final normalized = query.trim().toLowerCase();
              final filtered = normalized.isEmpty
                  ? docs
                  : docs.where((doc) {
                      final data = doc.data();
                      final name = ((data['name'] as String?) ?? '')
                          .toLowerCase();
                      final specialty = ((data['specialty'] as String?) ?? '')
                          .toLowerCase();
                      return name.contains(normalized) ||
                          specialty.contains(normalized);
                    }).toList();

              if (filtered.isEmpty) {
                return _PreviewEmpty(
                  message:
                      'No featured doctors match your search. Try a broader specialty or browse all doctors.',
                  onBrowse: onBrowseDoctors,
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final cardsPerRow = width >= 1080
                      ? 4
                      : width >= 760
                      ? 2
                      : 1;
                  const spacing = 10.0;
                  final itemWidth =
                      (width - (cardsPerRow - 1) * spacing) / cardsPerRow;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: filtered.map((doc) {
                      final data = doc.data();
                      final name = (data['name'] as String?) ?? 'Doctor';
                      final specialty =
                          (data['specialty'] as String?) ?? 'General Practice';
                      final imageUrl =
                          (data['profileImageUrl'] as String?) ?? '';
                      final rating = data['rating'];
                      final ratingText = rating is num
                          ? rating.toStringAsFixed(1)
                          : null;

                      return SizedBox(
                        width: itemWidth,
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundImage: imageUrl.isNotEmpty
                                        ? NetworkImage(imageUrl)
                                        : null,
                                    child: imageUrl.isEmpty
                                        ? const Icon(
                                            Icons.medical_services_outlined,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        Text(
                                          specialty,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.65),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (ratingText != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.12),
                                      ),
                                      child: Text(
                                        ratingText,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () => onViewProfile(doc),
                                icon: const Icon(Icons.info_outline),
                                label: const Text('View Profile'),
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

  bool _isDoctorDiscoverable(Map<String, dynamic> data) {
    final profileVisible = _readBool(data['profileVisible'], true);
    final acceptingBookings = _readBool(data['acceptingBookings'], true);
    return profileVisible && acceptingBookings;
  }

  bool _readBool(dynamic raw, bool fallback) {
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
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
}

class _PreviewEmpty extends StatelessWidget {
  final String message;
  final VoidCallback onBrowse;

  const _PreviewEmpty({required this.message, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onBrowse,
            icon: const Icon(Icons.manage_search_outlined),
            label: const Text('Browse Doctors'),
          ),
        ],
      ),
    );
  }
}

class _ConversionSection extends StatelessWidget {
  final VoidCallback onCreateAccount;
  final VoidCallback onBrowseDoctors;

  const _ConversionSection({
    required this.onCreateAccount,
    required this.onBrowseDoctors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      color: theme.colorScheme.primary.withValues(alpha: 0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready to Book Your Appointment?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your account to schedule care, or continue browsing available doctors as a guest.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: onCreateAccount,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Create Account'),
              ),
              OutlinedButton.icon(
                onPressed: onBrowseDoctors,
                icon: const Icon(Icons.manage_search_outlined),
                label: const Text('Browse Doctors'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LandingFooter extends StatelessWidget {
  final VoidCallback onAbout;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;
  final VoidCallback onContact;
  final VoidCallback onDoctorRegistration;

  const _LandingFooter({
    required this.onAbout,
    required this.onPrivacy,
    required this.onTerms,
    required this.onContact,
    required this.onDoctorRegistration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AstraCare',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Professional digital access for trusted healthcare appointments.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(onPressed: onAbout, child: const Text('About')),
              TextButton(
                onPressed: onPrivacy,
                child: const Text('Privacy Policy'),
              ),
              TextButton(onPressed: onTerms, child: const Text('Terms')),
              TextButton(onPressed: onContact, child: const Text('Contact')),
              TextButton(
                onPressed: onDoctorRegistration,
                child: const Text('Doctor Registration'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
