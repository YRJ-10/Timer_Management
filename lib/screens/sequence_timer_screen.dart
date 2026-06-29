import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/timer_sequence_model.dart';
import '../providers/sequence_timer_provider.dart';
import 'widgets/custom_time_picker.dart';

class SequenceTimerScreen extends StatelessWidget {
  const SequenceTimerScreen({super.key});

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _itemTitle(TimerSequenceItem item, int index) {
    final name = item.name.trim();
    return name.isEmpty ? 'Timer ${index + 1}' : name;
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.textSecondary),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );
  }

  void _showAddDialog(BuildContext context, SequenceTimerProvider provider) {
    String selectedName = '';
    int selectedM = 0;
    int selectedS = 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Add Timer',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          height: 272,
          child: Column(
            children: [
              TextField(
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  'Name',
                  hint: 'Work, Rest, Study...',
                ),
                onChanged: (value) => selectedName = value,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: CustomTimePicker(
                  showHours: false,
                  onTimeChanged: (h, m, s) {
                    selectedM = m;
                    selectedS = s;
                  },
                ),
              ),
            ],
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
              if (selectedM > 0 || selectedS > 0) {
                provider.addSequenceItem(
                  selectedM,
                  selectedS,
                  name: selectedName,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    SequenceTimerProvider provider,
    TimerSequenceItem item,
  ) {
    final nameController = TextEditingController(text: item.name);
    final minutesController = TextEditingController(
      text: item.minutes.toString(),
    );
    final secondsController = TextEditingController(
      text: item.seconds.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Edit Timer',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('Name'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minutesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Minutes'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: secondsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _inputDecoration('Seconds'),
                  ),
                ),
              ],
            ),
          ],
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
              final minutes = int.tryParse(minutesController.text) ?? 0;
              final seconds = (int.tryParse(secondsController.text) ?? 0).clamp(
                0,
                59,
              );
              if (minutes > 0 || seconds > 0) {
                provider.updateSequenceItem(
                  item.id,
                  name: nameController.text,
                  minutes: minutes,
                  seconds: seconds,
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).whenComplete(() {
      nameController.dispose();
      minutesController.dispose();
      secondsController.dispose();
    });
  }

  Widget _buildActiveTimer(SequenceTimerProvider provider) {
    final currentItem = provider.sequence[provider.currentIndex];

    return Column(
      children: [
        Text(
          'Step ${provider.currentIndex + 1} of ${provider.sequence.length}',
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          _itemTitle(currentItem, provider.currentIndex),
          style: const TextStyle(fontSize: 24, color: AppColors.secondary),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: provider.currentProgress.clamp(0, 1).toDouble(),
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
      ],
    );
  }

  Widget _buildActiveList(SequenceTimerProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.sequence.length,
      itemBuilder: (context, index) {
        final item = provider.sequence[index];
        final isCurrent = index == provider.currentIndex;
        return Card(
          color: isCurrent
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.surface,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: isCurrent ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              _itemTitle(item, index),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            trailing: Text(
              _formatTime(item.totalSeconds),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSetupList(BuildContext context, SequenceTimerProvider provider) {
    if (provider.sequence.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 32),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.format_list_numbered,
                color: AppColors.secondary,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Build your first routine',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create named steps like Work, Rest, Review, or Stretch. You can edit and reorder them anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () => _showAddDialog(context, provider),
              icon: const Icon(Icons.add),
              label: const Text('Add First Step'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(Icons.drag_handle, color: AppColors.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${provider.sequence.length} steps • ${_formatTime(provider.totalSequenceSeconds)} total',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Text(
                'Tap to edit',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.sequence.length,
          onReorder: provider.reorderSequenceItem,
          itemBuilder: (context, index) {
            final item = provider.sequence[index];
            return Card(
              key: ValueKey(item.id),
              color: AppColors.surface,
              child: ListTile(
                leading: const Icon(
                  Icons.drag_handle,
                  color: AppColors.textSecondary,
                ),
                title: Text(
                  _itemTitle(item, index),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  '${item.minutes}m ${item.seconds}s',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                onTap: () => _showEditDialog(context, provider, item),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.secondary),
                      onPressed: () => _showEditDialog(context, provider, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => provider.removeSequenceItem(item.id),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveControls(SequenceTimerProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton.small(
          heroTag: 'seq_btn_prev',
          onPressed: provider.previousTimer,
          backgroundColor: AppColors.surface,
          child: const Icon(Icons.skip_previous, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 16),
        FloatingActionButton(
          heroTag: 'seq_btn_pause',
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
        const SizedBox(width: 16),
        FloatingActionButton.small(
          heroTag: 'seq_btn_next',
          onPressed: provider.nextTimer,
          backgroundColor: AppColors.surface,
          child: const Icon(Icons.skip_next, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 16),
        FloatingActionButton.small(
          heroTag: 'seq_btn_stop',
          onPressed: () => provider.stop(),
          backgroundColor: AppColors.surface,
          child: const Icon(Icons.stop, color: AppColors.accent),
        ),
      ],
    );
  }

  Widget _buildSetupControls(
    BuildContext context,
    SequenceTimerProvider provider,
  ) {
    return Row(
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
                  const SnackBar(
                    content: Text('Add at least 2 timers to start'),
                  ),
                );
              }
            },
            backgroundColor: provider.sequence.length >= 2
                ? AppColors.primary
                : Colors.grey,
            shape: const CircleBorder(),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SequenceTimerProvider>(
      builder: (context, provider, child) {
        final showCountdown =
            provider.isRunning || provider.remainingSeconds > 0;

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Routine Timer',
                            style: AppStyles.headline,
                          ),
                          if (!showCountdown)
                            Row(
                              children: [
                                const Text(
                                  'Loop',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Switch(
                                  value: provider.isLooping,
                                  onChanged: provider.setLooping,
                                  activeThumbColor: AppColors.primary,
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (showCountdown) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: _buildActiveTimer(provider),
                        ),
                        _buildActiveList(provider),
                      ] else
                        _buildSetupList(context, provider),
                      const SizedBox(height: 32),
                      if (showCountdown)
                        _buildActiveControls(provider)
                      else
                        _buildSetupControls(context, provider),
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
