import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';
import 'package:dbs/core/widgets/reveal.dart';
import 'package:dbs/features/patient/presentation/pages/guest_doctor_profile_page.dart';
import 'package:flutter/material.dart';

class GuestDoctorsPageArgs {
  final String initialQuery;

  const GuestDoctorsPageArgs({this.initialQuery = ''});
}

class GuestDoctorsPage extends StatefulWidget {
  final String initialQuery;

  const GuestDoctorsPage({super.key, this.initialQuery = ''});

  @override
  State<GuestDoctorsPage> createState() => _GuestDoctorsPageState();
}

class _GuestDoctorsPageState extends State<GuestDoctorsPage> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Future<bool>> _availableTodayCache = {};

  String _query = '';
  String _specialtyFilter = 'All';
  String _locationFilter = 'All';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _searchController.text = _query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _availabilityFor(String doctorId) {
    final cached = _availableTodayCache[doctorId];
    if (cached != null) {
      return cached;
    }
    final future = _hasAvailableToday(doctorId);
    _availableTodayCache[doctorId] = future;
    return future;
  }

  Future<bool> _hasAvailableToday(String doctorId) async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    try {
      final snap = await FirebaseFirestore.instance
          .collection('availability')
          .doc(doctorId)
          .collection('slots')
          .where('isBooked', isEqualTo: false)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(dayEnd))
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _openProfile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    Navigator.pushNamed(
      context,
      Routes.guestDoctorProfile,
      arguments: GuestDoctorProfileArgs(
        doctorId: doc.id,
        initialData: doc.data(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Doctors'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, Routes.login),
            child: const Text('Login'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                          'Explore doctors as guest',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can view profiles and availability. Login is required before booking.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.68,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _query = value.trim();
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search by doctor name or specialty',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('doctors')
                        .where('isActive', isEqualTo: true)
                        .limit(60)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return AppCard(
                          child: Text(
                            'Failed to load doctors. Please try again.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        );
                      }

                      final docs = (snapshot.data?.docs ?? []).where((doc) {
                        return _isDoctorDiscoverable(doc.data());
                      }).toList();

                      if (docs.isEmpty) {
                        return AppCard(
                          child: Text(
                            'No doctors are currently available for public browsing.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        );
                      }

                      final specialties = <String>{'All'};
                      final locations = <String>{'All'};
                      for (final doc in docs) {
                        final data = doc.data();
                        final specialty = _readSpecialty(data);
                        final location = _readLocation(data);
                        if (specialty.isNotEmpty) {
                          specialties.add(specialty);
                        }
                        if (location.isNotEmpty) {
                          locations.add(location);
                        }
                      }

                      final specialtyOptions = specialties.toList()..sort();
                      final locationOptions = locations.toList()..sort();

                      final selectedSpecialty =
                          specialtyOptions.contains(_specialtyFilter)
                          ? _specialtyFilter
                          : 'All';
                      final selectedLocation =
                          locationOptions.contains(_locationFilter)
                          ? _locationFilter
                          : 'All';

                      final normalizedQuery = _query.toLowerCase();
                      final filtered = docs.where((doc) {
                        final data = doc.data();
                        final name = ((data['name'] as String?) ?? '')
                            .toLowerCase();
                        final specialty = _readSpecialty(data).toLowerCase();
                        final location = _readLocation(data);

                        if (selectedSpecialty != 'All' &&
                            _readSpecialty(data) != selectedSpecialty) {
                          return false;
                        }
                        if (selectedLocation != 'All' &&
                            location != selectedLocation) {
                          return false;
                        }
                        if (normalizedQuery.isEmpty) {
                          return true;
                        }
                        return name.contains(normalizedQuery) ||
                            specialty.contains(normalizedQuery);
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppCard(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 760;
                                if (narrow) {
                                  return Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        initialValue: selectedSpecialty,
                                        decoration: const InputDecoration(
                                          labelText: 'Specialty',
                                          prefixIcon: Icon(
                                            Icons.medical_services_outlined,
                                          ),
                                        ),
                                        items: specialtyOptions
                                            .map(
                                              (item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setState(() {
                                            _specialtyFilter = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        initialValue: selectedLocation,
                                        decoration: const InputDecoration(
                                          labelText: 'Location',
                                          prefixIcon: Icon(
                                            Icons.location_on_outlined,
                                          ),
                                        ),
                                        items: locationOptions
                                            .map(
                                              (item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setState(() {
                                            _locationFilter = value;
                                          });
                                        },
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: selectedSpecialty,
                                        decoration: const InputDecoration(
                                          labelText: 'Specialty',
                                          prefixIcon: Icon(
                                            Icons.medical_services_outlined,
                                          ),
                                        ),
                                        items: specialtyOptions
                                            .map(
                                              (item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setState(() {
                                            _specialtyFilter = value;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: selectedLocation,
                                        decoration: const InputDecoration(
                                          labelText: 'Location',
                                          prefixIcon: Icon(
                                            Icons.location_on_outlined,
                                          ),
                                        ),
                                        items: locationOptions
                                            .map(
                                              (item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          if (value == null) {
                                            return;
                                          }
                                          setState(() {
                                            _locationFilter = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: filtered.isEmpty
                                ? AppCard(
                                    child: Text(
                                      'No doctors match your current search and filters.',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      final width = constraints.maxWidth;
                                      final columns = width >= 1180
                                          ? 3
                                          : width >= 760
                                          ? 2
                                          : 1;
                                      const spacing = 12.0;
                                      final itemWidth =
                                          (width - (columns - 1) * spacing) /
                                          columns;

                                      return SingleChildScrollView(
                                        child: Wrap(
                                          spacing: spacing,
                                          runSpacing: spacing,
                                          children: filtered.map((doc) {
                                            final data = doc.data();
                                            final name =
                                                (data['name'] as String?) ??
                                                'Doctor';
                                            final specialty = _readSpecialty(
                                              data,
                                            );
                                            final imageUrl =
                                                (data['profileImageUrl']
                                                    as String?) ??
                                                '';
                                            final years = _readExperienceYears(
                                              data,
                                            );
                                            final location = _readLocation(
                                              data,
                                            );
                                            final bio =
                                                (data['bio'] as String?) ?? '';

                                            return SizedBox(
                                              width: itemWidth,
                                              child: AppCard(
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 26,
                                                          backgroundImage:
                                                              imageUrl
                                                                  .isNotEmpty
                                                              ? NetworkImage(
                                                                  imageUrl,
                                                                )
                                                              : null,
                                                          child:
                                                              imageUrl.isEmpty
                                                              ? const Icon(
                                                                  Icons
                                                                      .medical_services_outlined,
                                                                )
                                                              : null,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                name,
                                                                style: theme
                                                                    .textTheme
                                                                    .titleMedium
                                                                    ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                height: 2,
                                                              ),
                                                              Text(
                                                                specialty,
                                                                style: theme
                                                                    .textTheme
                                                                    .bodySmall
                                                                    ?.copyWith(
                                                                      color: theme
                                                                          .colorScheme
                                                                          .onSurface
                                                                          .withValues(
                                                                            alpha:
                                                                                0.67,
                                                                          ),
                                                                    ),
                                                              ),
                                                              if (location
                                                                  .isNotEmpty) ...[
                                                                const SizedBox(
                                                                  height: 2,
                                                                ),
                                                                Text(
                                                                  location,
                                                                  style: theme
                                                                      .textTheme
                                                                      .bodySmall
                                                                      ?.copyWith(
                                                                        color: theme
                                                                            .colorScheme
                                                                            .onSurface
                                                                            .withValues(
                                                                              alpha: 0.58,
                                                                            ),
                                                                      ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: [
                                                        if (years != null)
                                                          _CompactBadge(
                                                            icon: Icons
                                                                .work_outline,
                                                            label:
                                                                '$years years experience',
                                                          ),
                                                        FutureBuilder<bool>(
                                                          future:
                                                              _availabilityFor(
                                                                doc.id,
                                                              ),
                                                          builder:
                                                              (
                                                                context,
                                                                availableSnap,
                                                              ) {
                                                                final availableToday =
                                                                    availableSnap
                                                                        .data ==
                                                                    true;
                                                                return _CompactBadge(
                                                                  icon:
                                                                      availableToday
                                                                      ? Icons
                                                                            .check_circle_outline
                                                                      : Icons
                                                                            .schedule_outlined,
                                                                  label:
                                                                      availableToday
                                                                      ? 'Available today'
                                                                      : 'No slot today',
                                                                  active:
                                                                      availableToday,
                                                                );
                                                              },
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      _previewBio(bio),
                                                      maxLines: 3,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: theme
                                                                .colorScheme
                                                                .onSurface
                                                                .withValues(
                                                                  alpha: 0.76,
                                                                ),
                                                          ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: [
                                                        OutlinedButton.icon(
                                                          onPressed: () =>
                                                              _openProfile(doc),
                                                          icon: const Icon(
                                                            Icons.info_outline,
                                                          ),
                                                          label: const Text(
                                                            'View Profile',
                                                          ),
                                                        ),
                                                        ElevatedButton.icon(
                                                          onPressed: () =>
                                                              Navigator.pushNamed(
                                                                context,
                                                                Routes.login,
                                                              ),
                                                          icon: const Icon(
                                                            Icons
                                                                .login_outlined,
                                                          ),
                                                          label: const Text(
                                                            'Login to Book',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isDoctorDiscoverable(Map<String, dynamic> data) {
    final profileVisible = _readBool(data['profileVisible'], true);
    final acceptingBookings = _readBool(data['acceptingBookings'], true);
    return profileVisible && acceptingBookings;
  }

  String _readSpecialty(Map<String, dynamic> data) {
    final raw = (data['specialty'] as String?)?.trim() ?? '';
    if (raw.isEmpty) {
      return 'General Practice';
    }
    return raw;
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

  String _previewBio(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return 'Profile details and consultation summary are available in the full profile.';
    }
    return normalized;
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

class _CompactBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _CompactBadge({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primary.withValues(alpha: 0.14)
            : theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}
