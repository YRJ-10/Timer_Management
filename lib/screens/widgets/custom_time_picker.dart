import 'package:flutter/material.dart';
import '../../core/constants.dart';

class CustomTimePicker extends StatefulWidget {
  final bool showHours;
  final Function(int hours, int minutes, int seconds) onTimeChanged;

  const CustomTimePicker({
    Key? key,
    this.showHours = true,
    required this.onTimeChanged,
  }) : super(key: key);

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  int _selectedHour = 0;
  int _selectedMinute = 0;
  int _selectedSecond = 0;

  Widget _buildWheel(int maxValue, String label, ValueChanged<int> onChanged) {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          ListWheelScrollView.useDelegate(
            itemExtent: 50,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: maxValue,
              builder: (context, index) {
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 10,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _notifyChange() {
    widget.onTimeChanged(_selectedHour, _selectedMinute, _selectedSecond);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.showHours) ...[
            _buildWheel(24, "h", (val) {
              setState(() => _selectedHour = val);
              _notifyChange();
            }),
            const Text(":", style: TextStyle(fontSize: 32, color: AppColors.textSecondary)),
          ],
          _buildWheel(60, "m", (val) {
            setState(() => _selectedMinute = val);
            _notifyChange();
          }),
          const Text(":", style: TextStyle(fontSize: 32, color: AppColors.textSecondary)),
          _buildWheel(60, "s", (val) {
            setState(() => _selectedSecond = val);
            _notifyChange();
          }),
        ],
      ),
    );
  }
}
