// ignore_for_file: deprecated_member_use

part of 'admin_dashboard.dart';

class _AdminNavItem {
  final String label;
  final IconData icon;

  const _AdminNavItem({required this.label, required this.icon});
}

class _NavTile extends StatelessWidget {
  final _AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorFilter extends StatelessWidget {
  final String? selectedDoctorId;
  final ValueChanged<String?> onChanged;

  const _DoctorFilter({
    required this.selectedDoctorId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final items = <DropdownMenuItem<String?>>[
          const DropdownMenuItem(value: null, child: Text('All doctors')),
          ...docs.map((d) {
            final data = d.data();
            final name = (data['name'] as String?) ?? d.id;
            return DropdownMenuItem(value: d.id, child: Text(name));
          }),
        ];
        return DropdownButtonFormField<String?>(
          value: selectedDoctorId,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(labelText: 'Filter by doctor'),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ActionChip({required this.label, required this.icon});

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
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? Colors.green
        : theme.colorScheme.onSurface.withOpacity(0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _BarList extends StatelessWidget {
  final List<_ReportPoint> points;

  const _BarList({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxValue = points.isEmpty
        ? 1
        : points.map((e) => e.value).reduce(max);
    return Column(
      children: points.map((p) {
        final ratio = maxValue == 0 ? 0.0 : p.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(width: 52, child: Text(p.label)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ratio.clamp(0.05, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 32, child: Text('${p.value}')),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PieReportChart extends StatelessWidget {
  final List<_ReportPoint> points;

  const _PieReportChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Text('No data yet');

    final palette = [
      Colors.amber.shade700,
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.red.shade400,
    ];
    final entries = <MapEntry<_ReportPoint, Color>>[];
    for (var i = 0; i < points.length; i += 1) {
      entries.add(MapEntry(points[i], palette[i % palette.length]));
    }

    final nonZero = entries.where((e) => e.key.value > 0).toList();
    final total = entries.fold<int>(
      0,
      (current, entry) => current + entry.key.value,
    );
    if (nonZero.isEmpty || total == 0) return const Text('No data yet');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _PieChartPainter(
                sections: nonZero
                    .map(
                      (entry) => _PieChartSection(
                        value: entry.key.value.toDouble(),
                        color: entry.value,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: entry.value,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.key.label)),
                Text(
                  '${entry.key.value} (${((entry.key.value / total) * 100).toStringAsFixed(1)}%)',
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PieChartSection {
  final double value;
  final Color color;

  const _PieChartSection({required this.value, required this.color});
}

class _PieChartPainter extends CustomPainter {
  final List<_PieChartSection> sections;

  const _PieChartPainter({required this.sections});

  @override
  void paint(Canvas canvas, Size size) {
    if (sections.isEmpty) return;
    final total = sections.fold<double>(
      0,
      (current, section) => current + section.value,
    );
    if (total <= 0) return;

    final radius = min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    var startAngle = -pi / 2;

    final paint = Paint()..style = PaintingStyle.fill;
    for (final section in sections) {
      final sweep = (section.value / total) * 2 * pi;
      paint.color = section.color;
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    if (oldDelegate.sections.length != sections.length) return true;
    for (var i = 0; i < sections.length; i += 1) {
      if (oldDelegate.sections[i].value != sections[i].value ||
          oldDelegate.sections[i].color != sections[i].color) {
        return true;
      }
    }
    return false;
  }
}

class _RankList extends StatelessWidget {
  final List<_ReportPoint> points;

  const _RankList({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Text('No data yet');
    }
    return Column(
      children: points.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(p.label)),
              Text('${p.value}'),
            ],
          ),
        );
      }).toList(),
    );
  }
}

