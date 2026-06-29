import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/simple_timer_provider.dart';
import 'widgets/custom_time_picker.dart';
import 'widgets/template_chip.dart';

class SimpleTimerScreen extends StatelessWidget {
  const SimpleTimerScreen({Key? key}) : super(key: key);

  String _formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showAddDialog(BuildContext context, SimpleTimerProvider provider) {
    int selH = 0, selM = 0, selS = 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Add Template',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          height: 200,
          child: CustomTimePicker(
            showHours: true,
            onTimeChanged: (h, m, s) {
              selH = h;
              selM = m;
              selS = s;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              provider.addTemplate(selH, selM, selS);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    SimpleTimerProvider provider,
    int index,
    int totalSecs,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Template?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove template ${_formatTime(totalSecs)}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              provider.removeTemplate(index);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleTimerProvider>(
      builder: (context, provider, child) {
        final bool showCountdown =
            provider.isRunning || provider.remainingSeconds > 0;

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Timer', style: AppStyles.headline),
                      const SizedBox(height: 32),

                      if (showCountdown) ...[
                        // Active Countdown UI
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: SizedBox(
                            width: 280,
                            height: 280,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: provider.progress
                                        .clamp(0, 1)
                                        .toDouble(),
                                    strokeWidth: 14,
                                    backgroundColor: AppColors.surface,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                Text(
                                  _formatTime(provider.remainingSeconds),
                                  style: AppStyles.timerTextBig,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Setup UI
                        CustomTimePicker(
                          showHours: true,
                          onTimeChanged: (h, m, s) {
                            provider.setTime(h, m, s);
                          },
                        ),
                        const SizedBox(height: 32),

                        // Templates Row
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            for (int i = 0; i < provider.templates.length; i++)
                              TemplateChip(
                                label: _formatTime(provider.templates[i]),
                                onTap: () {
                                  provider.setTimeFromSeconds(
                                    provider.templates[i],
                                  );
                                  provider.start();
                                },
                                onLongPress: () => _showDeleteDialog(
                                  context,
                                  provider,
                                  i,
                                  provider.templates[i],
                                ),
                              ),
                            if (provider.templates.length < 5)
                              ActionChip(
                                label: const Icon(
                                  Icons.add,
                                  color: AppColors.textPrimary,
                                  size: 20,
                                ),
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ), // fixed deprecation
                                onPressed: () =>
                                    _showAddDialog(context, provider),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (provider.templates.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Hold to delete template',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],

                      const SizedBox(height: 32),

                      // Controls
                      if (showCountdown) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FloatingActionButton(
                              heroTag: 'btn1',
                              onPressed: () {
                                if (provider.isPaused) {
                                  provider.start();
                                } else {
                                  provider.pause();
                                }
                              },
                              backgroundColor: AppColors.surface,
                              child: Icon(
                                provider.isPaused
                                    ? Icons.play_arrow
                                    : Icons.pause,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 24),
                            FloatingActionButton(
                              heroTag: 'btn2',
                              onPressed: () => provider.stop(),
                              backgroundColor: AppColors.surface,
                              child: const Icon(
                                Icons.stop,
                                color: AppColors.accent,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: FloatingActionButton(
                            heroTag: 'btn3',
                            onPressed: () {
                              if (provider.hours > 0 ||
                                  provider.minutes > 0 ||
                                  provider.seconds > 0) {
                                provider.start();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a time'),
                                  ),
                                );
                              }
                            },
                            backgroundColor: AppColors.primary,
                            shape: const CircleBorder(),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
