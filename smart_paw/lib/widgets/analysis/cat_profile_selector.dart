import 'package:flutter/material.dart';

import '../../services/cat_api_service.dart';
import 'analysis_ui.dart';

class CatProfileSelector extends StatelessWidget {
  const CatProfileSelector({
    super.key,
    required this.cats,
    required this.selectedCatId,
    required this.onSelect,
  });

  final List<Map<String, dynamic>> cats;
  final int? selectedCatId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AnalysisUi.selectorBarBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          const Text(
            'Cat Profile',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AnalysisUi.muted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: cats.isEmpty
                ? const SizedBox.shrink()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final (i, cat) in cats.indexed) ...[
                          if (i > 0) const SizedBox(width: 10),
                          _CatAvatar(
                            cat: cat,
                            selected: selectedCatId ==
                                (cat['cat_id'] as num?)?.toInt(),
                            onTap: () {
                              final id = (cat['cat_id'] as num?)?.toInt();
                              if (id != null) onSelect(id);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CatAvatar extends StatelessWidget {
  const _CatAvatar({
    required this.cat,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> cat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slug = cat['slug']?.toString() ?? '';
    final asset = CatApiService.assetPathForServer(
      cat['avatar_url']?.toString(),
      slug,
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AnalysisUi.accentPink : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AnalysisUi.accentPink.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: Colors.white,
                  child: Icon(
                    Icons.pets_rounded,
                    size: 22,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AnalysisUi.accentPink,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
