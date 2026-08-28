import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../providers/app_state.dart';
import '../theme/palette.dart';

class BottomNav extends StatelessWidget {
  final NavTab active;
  final ValueChanged<NavTab> onChange;
  final NavLabels labels;

  const BottomNav({
    super.key,
    required this.active,
    required this.onChange,
    required this.labels,
  });

  static const _tabs = <(NavTab, IconData)>[
    (NavTab.home, Icons.home_rounded),
    (NavTab.catalog, Icons.grid_view_rounded),
    (NavTab.growth, Icons.trending_up_rounded),
    (NavTab.help, Icons.support_agent_rounded),
  ];

  String _label(NavTab t) => switch (t) {
    NavTab.home    => labels.home,
    NavTab.catalog => labels.catalog,
    NavTab.growth  => labels.growth,
    NavTab.help    => labels.support,
  };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.ink950 : Colors.white;
    final border = dark ? AppColors.ink700 : AppColors.ink200;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        children: _tabs.map((entry) {
          final (tab, icon) = entry;
          final isActive = tab == active;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChange(tab),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.saffron50.withAlpha(dark ? 40 : 255) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 24, color: isActive ? AppColors.saffron600 : AppColors.ink500),
                    const SizedBox(height: 4),
                    Text(
                      _label(tab),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? AppColors.saffron600 : AppColors.ink500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
