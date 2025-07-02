import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../shared/models/race.dart';
import '../controller/race_screen_controller.dart';
import '../widgets/flow_notification.dart';

// Simplified color function
Color _getStatusColor(String flowState) {
  switch (flowState) {
    case Race.FLOW_SETUP:
      return Colors.amber;
    case Race.FLOW_SETUP_COMPLETED:
    case Race.FLOW_PRE_RACE:
      return Colors.blue;
    case Race.FLOW_PRE_RACE_COMPLETED:
    case Race.FLOW_POST_RACE:
      return Colors.purple;
    // case Race.FLOW_POST_RACE_COMPLETED:
    case Race.FLOW_FINISHED:
      return Colors.green;
    default:
      return Colors.grey;
  }
}

// Simplified icon function
IconData _getStatusIcon(String flowState) {
  switch (flowState) {
    case Race.FLOW_SETUP:
    case Race.FLOW_SETUP_COMPLETED:
      return Icons.settings;
    case Race.FLOW_PRE_RACE:
    case Race.FLOW_PRE_RACE_COMPLETED:
      return Icons.timer;
    case Race.FLOW_POST_RACE:
      return Icons.flag;
    // case Race.FLOW_POST_RACE_COMPLETED:
    case Race.FLOW_FINISHED:
      return Icons.check_circle;
    default:
      return Icons.help;
  }
}

class RaceHeader extends StatelessWidget {
  final RaceController controller;
  const RaceHeader({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
            child: Text(
          controller.race!.race_name,
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.primaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        )),

        // Only show flow notification for non-finished states
        if (controller.race!.flowState != Race.FLOW_FINISHED)
          FlowNotification(
            flowState: controller.race!.flowState,
            color: _getStatusColor(controller.race!.flowState),
            icon: _getStatusIcon(controller.race!.flowState),
            continueAction: () => controller.continueRaceFlow(context),
          ),
      ],
    );
  }
}
