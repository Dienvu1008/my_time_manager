import 'package:flutter/material.dart';
import 'package:my_time_manager/data/models/model_measurable_task.dart';

class TargetBlockListTile extends StatefulWidget {
  final TextEditingController unitController;
  final TextEditingController targetAtLeastController;
  final TextEditingController targetAtMostController;
  final TextEditingController hasBeenDoneController;
  final TargetType targetType;
  final ValueChanged<TargetType> onTargetTypeChanged;

  TargetBlockListTile(
      {required this.unitController,
      required this.targetAtLeastController,
      required this.targetAtMostController,
      required this.hasBeenDoneController,
      required this.targetType,
      required this.onTargetTypeChanged});

  @override
  _TargetBlockListTileState createState() => _TargetBlockListTileState();
}

class _TargetBlockListTileState extends State<TargetBlockListTile> {
  TargetType _targetType = TargetType.about;

  @override
  void initState() {
    super.initState();
    _targetType = widget.targetType;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<TargetType>(
                value: _targetType,
                onChanged: (value) {
                  setState(() => _targetType = value!);
                  widget.onTargetTypeChanged(_targetType);
                },
                items: TargetType.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e == TargetType.atLeast
                              ? 'at least'
                              : e == TargetType.atMost
                                  ? 'at most'
                                  : 'about'),
                        ))
                    .toList(),
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Target Type',
                    floatingLabelBehavior: FloatingLabelBehavior.auto),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a target type';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: widget.unitController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Unit',
                    floatingLabelBehavior: FloatingLabelBehavior.auto),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please input unit';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (_targetType == TargetType.atLeast ||
                _targetType == TargetType.about)
              Expanded(
                child: TextFormField(
                  controller: widget.targetAtLeastController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'min.',
                      floatingLabelBehavior: FloatingLabelBehavior.auto),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: false),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập giá trị ít nhất';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Vui lòng nhập số';
                    }
                    return null;
                  },
                ),
              ),
            if (_targetType == TargetType.about) const SizedBox(width: 12),
            if (_targetType == TargetType.atMost ||
                _targetType == TargetType.about)
              Expanded(
                child: TextFormField(
                  controller: widget.targetAtMostController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'max.',
                      floatingLabelBehavior: FloatingLabelBehavior.auto),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: false),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập giá trị nhiều nhất';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Vui lòng nhập số';
                    }
                    return null;
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.hasBeenDoneController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Has been done',
                    floatingLabelBehavior: FloatingLabelBehavior.auto),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: false),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá trị';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Vui lòng nhập số';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(
          height: 4,
        ),
      ],
    );
  }
}
