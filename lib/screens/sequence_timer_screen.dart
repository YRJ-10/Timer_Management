import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/sequence_timer_provider.dart';
import '../models/timer_sequence_model.dart';
import 'widgets/custom_time_picker.dart';

class SequenceTimerScreen extends StatelessWidget {
  const SequenceTimerScreen({Key? key}) : super(key: key);

  String _formatTime(int totalSeconds) {
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showAddDialog(BuildContext context, SequenceTimerProvider provider) {
    int selectedM = 0;
    int selectedS = 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Package', style: TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          height: 200,
          child: CustomTimePicker(
            showHours: false,
            onTimeChanged: (h, m, s) {
              selectedM = m;
              selectedS = s;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (selectedM > 0 || selectedS > 0) {
                provider.addSequenceItem(selectedM, selectedS);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SequenceTimerProvider>(
      builder: (context, provider, child) {
        final bool showCountdown = provider.isRunning || provider.remainingSeconds > 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sequence Timer', style: AppStyles.headline),
                  if (!showCountdown)
                    Row(
                      children: [
                        const Text('Loop', style: TextStyle(color: AppColors.textPrimary)),
                        Switch(
                          value: provider.isLooping,
                          onChanged: (val) => provider.toggleLoop(),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (showCountdown) ...[
                // Active UI
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Package ${provider.currentIndex + 1}',
                          style: const TextStyle(fontSize: 24, color: AppColors.secondary),
                        ),
                        Text(
                          _formatTime(provider.remainingSeconds),
                          style: AppStyles.timerTextBig,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ListView.builder(
                    itemCount: provider.sequence.length,
                    itemBuilder: (context, index) {
                      final item = provider.sequence[index];
                      final isCurrent = index == provider.currentIndex;
                      return Card(
                        color: isCurrent ? AppColors.primary.withOpacity(0.3) : AppColors.surface,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isCurrent ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text('Package ${index + 1}', style: const TextStyle(color: AppColors.textPrimary)),
                          trailing: Text(
                            _formatTime(item.totalSeconds),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                // Setup UI
                Expanded(
                  child: provider.sequence.isEmpty
                      ? const Center(
                          child: Text(
                            'No packages added yet.\nPress + to add.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          itemCount: provider.sequence.length,
                          itemBuilder: (context, index) {
                            final item = provider.sequence[index];
                            return Card(
                              color: AppColors.surface,
                              child: ListTile(
                                title: Text('Package ${index + 1}', style: const TextStyle(color: AppColors.textPrimary)),
                                subtitle: Text('${item.minutes}m ${item.seconds}s', style: const TextStyle(color: AppColors.textSecondary)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => provider.removeSequenceItem(item.id),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Controls
              if (showCountdown) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton(
                      heroTag: 'seq_btn1',
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
                      heroTag: 'seq_btn2',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (provider.sequence.length < 10)
                      FloatingActionButton(
                        heroTag: 'seq_btn_add',
                        onPressed: () => _showAddDialog(context, provider),
                        backgroundColor: AppColors.surface,
                        child: const Icon(Icons.add, color: AppColors.textPrimary),
                      ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: FloatingActionButton(
                        heroTag: 'seq_btn_play',
                        onPressed: () {
                          if (provider.sequence.length >= 2) {
                            provider.start();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Add at least 2 packages to start')),
                            );
                          }
                        },
                        backgroundColor: provider.sequence.length >= 2 ? AppColors.primary : Colors.grey,
                        shape: const CircleBorder(),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
