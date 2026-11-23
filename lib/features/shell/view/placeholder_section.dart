import 'package:ckd_design_system/ckd_design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Stand-in for sections whose module isn't built yet.
class PlaceholderSection extends StatelessWidget {
  const PlaceholderSection({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DsSpacing.insetLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: DsTypography.h3),
          const SizedBox(height: DsSpacing.stackLg),
          DsEmptyState(
            icon: Icons.construction_outlined,
            title: 'Coming soon',
            message: message,
            action: action,
          ),
        ],
      ),
    );
  }
}
