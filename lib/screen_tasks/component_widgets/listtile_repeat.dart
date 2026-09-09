import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'repeat_rule.dart';

/// ListTile chọn quy tắc lặp cho time interval.
///
/// Mỗi khi người dùng thay đổi lựa chọn, [onChanged] được gọi với [RepeatRule]
/// mới, để màn hình cha (bottomsheet) đọc và sinh các time interval lặp lại.
class RepeatListTile extends StatefulWidget {
  const RepeatListTile({super.key, required this.onChanged});

  final ValueChanged<RepeatRule> onChanged;

  @override
  State<RepeatListTile> createState() => _RepeatListTileState();
}

class _RepeatListTileState extends State<RepeatListTile> {
  bool _showRepeatOptions = false;

  // Trạng thái tổng hợp của quy tắc lặp.
  RepeatFrequency _frequency = RepeatFrequency.none;
  bool _showCustom = false;

  // Cấu hình cho chế độ Custom.
  int _repeatValue = 1;
  // Loại đơn vị lặp khi Custom: dùng lại RepeatFrequency (daily/weekly/monthly/yearly).
  RepeatFrequency _customUnit = RepeatFrequency.daily;
  final Map<int, bool> _selectedWeekdays = {
    DateTime.monday: false,
    DateTime.tuesday: false,
    DateTime.wednesday: false,
    DateTime.thursday: false,
    DateTime.friday: false,
    DateTime.saturday: false,
    DateTime.sunday: false,
  };

  RepeatEndMode _endMode = RepeatEndMode.never;
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  int _occurrences = 5;

  static const _weekdayLabels = {
    DateTime.monday: 'T2',
    DateTime.tuesday: 'T3',
    DateTime.wednesday: 'T4',
    DateTime.thursday: 'T5',
    DateTime.friday: 'T6',
    DateTime.saturday: 'T7',
    DateTime.sunday: 'CN',
  };

  /// Dựng RepeatRule hiện tại từ state và bắn ra ngoài.
  void _emit() {
    final RepeatRule rule;
    if (_frequency == RepeatFrequency.none) {
      rule = RepeatRule.none;
    } else if (_showCustom) {
      final selectedDays = _selectedWeekdays.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toSet();
      rule = RepeatRule(
        frequency: _customUnit,
        interval: _repeatValue,
        weekdays: _customUnit == RepeatFrequency.weekly ? selectedDays : const {},
        endMode: _endMode,
        endDate: _endMode == RepeatEndMode.onDate ? _endDate : null,
        occurrences: _occurrences,
      );
    } else {
      // Các preset (hằng ngày/tuần/tháng/năm): interval 1, không giới hạn.
      rule = RepeatRule(frequency: _frequency);
    }
    widget.onChanged(rule);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.repeat_outlined),
          title: const Text('Lặp lại?'),
          subtitle: Text(_frequency == RepeatFrequency.none
              ? 'Không lặp lại'
              : (_showCustom ? 'Tùy chỉnh' : _frequency.label)),
          onTap: () =>
              setState(() => _showRepeatOptions = !_showRepeatOptions),
        ),
        if (_showRepeatOptions) ...[
          _presetTile('Không lặp lại', RepeatFrequency.none, custom: false),
          _presetTile('Hằng ngày', RepeatFrequency.daily, custom: false),
          _presetTile('Hằng tuần', RepeatFrequency.weekly, custom: false),
          _presetTile('Hằng tháng', RepeatFrequency.monthly, custom: false),
          _presetTile('Hằng năm', RepeatFrequency.yearly, custom: false),
          RadioListTile<bool>(
            title: const Text('Tùy chỉnh'),
            value: true,
            groupValue: _showCustom,
            onChanged: (_) {
              setState(() {
                _showCustom = true;
                // Khi vào Custom mà đang ở none, mặc định chuyển sang daily.
                if (_frequency == RepeatFrequency.none) {
                  _frequency = RepeatFrequency.daily;
                }
                _customUnit = _frequency == RepeatFrequency.none
                    ? RepeatFrequency.daily
                    : _frequency;
              });
              _emit();
            },
          ),
          if (_showCustom) _buildCustomOptions(),
        ],
        const Divider(height: 4),
      ],
    );
  }

  Widget _presetTile(String label, RepeatFrequency freq,
      {required bool custom}) {
    // Radio này chọn preset (không Custom). Dùng một khóa chuỗi để phân biệt
    // với lựa chọn Custom.
    final selected = !_showCustom && _frequency == freq;
    return RadioListTile<bool>(
      title: Text(label),
      value: true,
      groupValue: selected,
      onChanged: (_) {
        setState(() {
          _frequency = freq;
          _showCustom = false;
        });
        _emit();
      },
    );
  }

  Widget _buildCustomOptions() {
    return Column(
      children: [
        ListTile(
          title: Row(
            children: [
              const Text('Lặp mỗi'),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  initialValue: '$_repeatValue',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      _repeatValue = parsed;
                      _emit();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<RepeatFrequency>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  value: _customUnit,
                  items: const [
                    DropdownMenuItem(
                        value: RepeatFrequency.daily, child: Text('ngày')),
                    DropdownMenuItem(
                        value: RepeatFrequency.weekly, child: Text('tuần')),
                    DropdownMenuItem(
                        value: RepeatFrequency.monthly, child: Text('tháng')),
                    DropdownMenuItem(
                        value: RepeatFrequency.yearly, child: Text('năm')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _customUnit = value;
                      _frequency = value;
                    });
                    _emit();
                  },
                ),
              ),
            ],
          ),
        ),
        // Chọn thứ trong tuần khi lặp theo tuần.
        if (_customUnit == RepeatFrequency.weekly)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _selectedWeekdays.keys.map((wd) {
                final on = _selectedWeekdays[wd]!;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedWeekdays[wd] = !on);
                    _emit();
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: on
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Text(
                      _weekdayLabels[wd]!,
                      style: TextStyle(
                        color: on
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        // Điều kiện kết thúc.
        ListTile(title: Text('Kết thúc', style: Theme.of(context).textTheme.titleSmall)),
        RadioListTile<RepeatEndMode>(
          title: const Text('Không bao giờ'),
          value: RepeatEndMode.never,
          groupValue: _endMode,
          onChanged: (v) {
            setState(() => _endMode = v!);
            _emit();
          },
        ),
        RadioListTile<RepeatEndMode>(
          title: Row(
            children: [
              const Text('Vào ngày '),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                  );
                  if (picked != null) {
                    setState(() {
                      _endDate = picked;
                      _endMode = RepeatEndMode.onDate;
                    });
                    _emit();
                  }
                },
                child: Text(
                    '${_endDate.day}/${_endDate.month}/${_endDate.year}'),
              ),
            ],
          ),
          value: RepeatEndMode.onDate,
          groupValue: _endMode,
          onChanged: (v) {
            setState(() => _endMode = v!);
            _emit();
          },
        ),
        RadioListTile<RepeatEndMode>(
          title: Row(
            children: [
              const Text('Sau '),
              SizedBox(
                width: 56,
                child: TextFormField(
                  initialValue: '$_occurrences',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      _occurrences = parsed;
                      if (_endMode == RepeatEndMode.afterOccurrences) _emit();
                    }
                  },
                ),
              ),
              const Text(' lần'),
            ],
          ),
          value: RepeatEndMode.afterOccurrences,
          groupValue: _endMode,
          onChanged: (v) {
            setState(() => _endMode = v!);
            _emit();
          },
        ),
      ],
    );
  }
}
