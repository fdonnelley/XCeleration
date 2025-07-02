import 'package:flutter/material.dart';
import 'package:xceleration/core/utils/logger.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/components/button_components.dart';
import '../../../core/utils/database_helper.dart';
import 'package:xceleration/core/utils/color_utils.dart';
import 'competing_teams_field.dart';
import 'modern_detail_row.dart';
import '../controller/race_screen_controller.dart';
import 'race_name_field.dart';
import 'race_location_field.dart';
import 'race_date_field.dart';
import 'race_distance_field.dart';
import 'package:provider/provider.dart';

class RaceDetailsTab extends StatefulWidget {
  final RaceController controller;
  const RaceDetailsTab({super.key, required this.controller});

  @override
  State<RaceDetailsTab> createState() => _RaceDetailsTabState();
}

class _RaceDetailsTabState extends State<RaceDetailsTab> {
  bool detailsChanged = false;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _teamsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _locationController.dispose();
    _distanceController.dispose();
    _unitController.dispose();
    _teamsController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    final race = widget.controller.race!;
    _dateController.text = race.raceDate != null
        ? DateFormat('yyyy-MM-dd').format(race.raceDate!)
        : '';
    _locationController.text = race.location;
    _distanceController.text =
        race.distance > 0 ? race.distance.toString() : '';
    _unitController.text =
        race.distanceUnit.isNotEmpty ? race.distanceUnit : 'mi';
    _teamsController.text = race.teams.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.controller,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final race = widget.controller.race!;
          bool hasTeams = race.teams.isNotEmpty;
          int runnerCount = 0;

          return FutureBuilder(
            future: DatabaseHelper.instance.getRaceRunners(race.raceId),
            builder: (context, snapshot) {
              runnerCount = snapshot.hasData
                  ? (snapshot.data as List).length
                  : runnerCount;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Race Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      widget.controller.isInEditMode
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RaceNameField(
                                  controller: widget.controller,
                                  setSheetState: setState,
                                  onChanged: (_) {
                                    setState(() {
                                      detailsChanged = true;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                RaceLocationField(
                                  controller: widget.controller,
                                  setSheetState: setState,
                                  onChanged: (_) {
                                    setState(() {
                                      detailsChanged = true;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                RaceDateField(
                                  controller: widget.controller,
                                  setSheetState: setState,
                                  onChanged: (_) {
                                    setState(() {
                                      detailsChanged = true;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                RaceDistanceField(
                                  controller: widget.controller,
                                  setSheetState: setState,
                                  onChanged: (_) {
                                    setState(() {
                                      detailsChanged = true;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                CompetingTeamsField(
                                  controller: widget.controller,
                                  setSheetState: setState,
                                  onChanged: (value) {
                                    setState(() {
                                      detailsChanged = true;
                                      hasTeams = value.isNotEmpty;
                                    });
                                    Logger.d('Has teams: $hasTeams');
                                  },
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ModernDetailRow(
                                  label: 'Race Name',
                                  value: race.raceName,
                                  icon: Icons.emoji_events,
                                ),
                                const SizedBox(height: 12),
                                ModernDetailRow(
                                  label: 'Location',
                                  value: race.location,
                                  icon: Icons.location_on,
                                ),
                                const SizedBox(height: 12),
                                ModernDetailRow(
                                  label: 'Race Date',
                                  value: race.raceDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(race.raceDate!)
                                      : 'Not set',
                                  icon: Icons.calendar_today,
                                ),
                                const SizedBox(height: 12),
                                ModernDetailRow(
                                  label: 'Distance',
                                  value:
                                      '${race.distance} ${race.distanceUnit}',
                                  icon: Icons.straighten,
                                ),
                                const SizedBox(height: 12),
                                ModernDetailRow(
                                  label: 'Teams',
                                  value: race.teams.join(', '),
                                  icon: Icons.groups,
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => widget.controller
                            .loadRunnersManagementScreenWithConfirmation(
                                context,
                                isViewMode: !widget.controller.isInEditMode),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: ColorUtils.withOpacity(
                                      AppColors.primaryColor, 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.group_rounded,
                                    color: AppColors.primaryColor, size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Runners',
                                      style: AppTypography.bodyRegular.copyWith(
                                        color: ColorUtils.withOpacity(
                                            AppColors.darkColor, 0.6),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$runnerCount runner${runnerCount == 1 ? '' : 's'}',
                                      style:
                                          AppTypography.bodySemibold.copyWith(
                                        color: AppColors.darkColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppColors.primaryColor,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  if (widget.controller.isInEditMode) ...[
                    const SizedBox(height: 24),
                    FullWidthButton(
                      text: 'Save Changes',
                      onPressed: () {
                        setState(() {
                          detailsChanged = false;
                        });
                        widget.controller.saveRaceDetails(context);
                      },
                      isEnabled: detailsChanged,
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
