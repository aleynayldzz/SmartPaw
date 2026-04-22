import 'package:flutter/material.dart';

// Alt navigasyon: görünüm amaçlı
class MainBottomNav extends StatelessWidget {
  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const _bg = Color(0xFFFDFBF0);
  static const _fg = Color(0xFF333333);
  static const _fgMuted = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    final items = <_NavSpec>[
      (label: 'Home', icon: Icons.home_outlined),
      (label: 'Health', icon: Icons.favorite_border),
      (label: 'Care', icon: Icons.pets),
      (label: 'Analytics', icon: Icons.bar_chart),
      (label: 'Profile', icon: Icons.person_outline),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Material(
        color: _bg,
        elevation: 0,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8, top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List<Widget>.generate(
              items.length,
              (i) => Expanded(
                child: _NavTile(
                  spec: items[i],
                  selected: i == currentIndex,
                  onTap: () => onSelect(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef _NavSpec = ({String label, IconData icon});

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? MainBottomNav._fg : MainBottomNav._fgMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spec.icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
