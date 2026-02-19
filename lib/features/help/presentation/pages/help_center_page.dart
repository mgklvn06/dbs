import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  static const List<_HelpSection> _sections = <_HelpSection>[
    _HelpSection(
      icon: Icons.flag_outlined,
      title: 'Getting Started',
      summary: 'Set up your account so booking and reminders work smoothly.',
      points: <String>[
        'Open Profile Settings and confirm your full name and phone number.',
        'Use a valid phone in format 2547XXXXXXXX for M-Pesa payments.',
        'Turn on booking reminders so you do not miss scheduled visits.',
      ],
    ),
    _HelpSection(
      icon: Icons.search_outlined,
      title: 'Find The Right Doctor',
      summary:
          'Use search and filters to narrow doctors by specialty and availability.',
      points: <String>[
        'Go to Find Doctors from the dashboard.',
        'Filter by specialty, then open a profile to review experience and details.',
        'Use Book Appointment when you are ready to select date and time.',
      ],
    ),
    _HelpSection(
      icon: Icons.event_note_outlined,
      title: 'Book An Appointment',
      summary: 'Follow the booking flow and confirm your slot before checkout.',
      points: <String>[
        'Pick the doctor, date, and available time slot.',
        'Review appointment details before confirming payment.',
        'After payment request is sent, wait for M-Pesa PIN prompt on your phone.',
      ],
    ),
    _HelpSection(
      icon: Icons.payments_outlined,
      title: 'M-Pesa Payments',
      summary:
          'Payment status updates after Daraja callback is processed by backend.',
      points: <String>[
        'If prompt does not appear, confirm your phone number is correct and active.',
        'Keep the app open while payment remains in pending state.',
        'Check My Appointments to confirm status changes to confirmed or paid.',
      ],
    ),
    _HelpSection(
      icon: Icons.history_outlined,
      title: 'Manage Existing Appointments',
      summary: 'Track history and manage active bookings from one screen.',
      points: <String>[
        'Open My Appointments to view pending, confirmed, and completed visits.',
        'Use search and status filters for faster tracking.',
        'Cancel early when plans change to avoid policy restrictions.',
      ],
    ),
    _HelpSection(
      icon: Icons.shield_outlined,
      title: 'Account, Security, And Privacy',
      summary: 'Control profile visibility and communication preferences.',
      points: <String>[
        'Use Profile Settings to control what doctors can view.',
        'Change password regularly if using email and password sign-in.',
        'Sign out from shared devices after every session.',
      ],
    ),
    _HelpSection(
      icon: Icons.build_outlined,
      title: 'Troubleshooting',
      summary: 'Quick checks for common issues before contacting support.',
      points: <String>[
        'Refresh the page if data does not update immediately.',
        'Check internet connection when loading fails or actions time out.',
        'Restart the app if payment or booking status appears stuck.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(22),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.support_agent_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DBS Help Center',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This guide explains how to move through the app, complete bookings, and resolve common payment or scheduling issues quickly.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.75),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useTwoColumns = constraints.maxWidth >= 860;
                        final cardWidth = useTwoColumns
                            ? (constraints.maxWidth - 16) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: _sections
                              .map(
                                (section) => SizedBox(
                                  width: cardWidth,
                                  child: _HelpSectionCard(section: section),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.contact_support_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Need More Help?',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'If an issue continues after these checks, contact your clinic administrator and include: phone number used, appointment date, and payment reference (if available).',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.75,
                              ),
                              height: 1.35,
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
        ),
      ),
    );
  }
}

class _HelpSectionCard extends StatelessWidget {
  final _HelpSection section;

  const _HelpSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  section.icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            section.summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          for (final point in section.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
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

class _HelpSection {
  final IconData icon;
  final String title;
  final String summary;
  final List<String> points;

  const _HelpSection({
    required this.icon,
    required this.title,
    required this.summary,
    required this.points,
  });
}
