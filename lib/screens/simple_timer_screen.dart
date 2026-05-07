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

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleTimerProvider>(
      builder: (context, provider, child) {
        final bool showCountdown = provider.isRunning || provider.remainingSeconds > 0;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Timer',
                style: AppStyles.headline,
              ),
              const Spacer(),
              
              if (showCountdown) ...[
                // Active Countdown UI
                Text(
                  _formatTime(provider.remainingSeconds),
                  style: AppStyles.timerTextBig,
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
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    TemplateChip(label: '1 Min', onTap: () { provider.setTime(0, 1, 0); provider.start(); }),
                    TemplateChip(label: '5 Min', onTap: () { provider.setTime(0, 5, 0); provider.start(); }),
                    TemplateChip(label: '10 Min', onTap: () { provider.setTime(0, 10, 0); provider.start(); }),
                    TemplateChip(label: '15 Min', onTap: () { provider.setTime(0, 15, 0); provider.start(); }),
                  ],
                ),
              ],
              
              const Spacer(),
              
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
                        provider.isPaused ? Icons.play_arrow : Icons.pause,
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
                  width: 120,
                  height: 120,
                  child: FloatingActionButton(
                    heroTag: 'btn3',
                    onPressed: () {
                      if (provider.hours > 0 || provider.minutes > 0 || provider.seconds > 0) {
                        provider.start();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a time')),
                        );
                      }
                    },
                    backgroundColor: AppColors.primary,
                    shape: const CircleBorder(),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
