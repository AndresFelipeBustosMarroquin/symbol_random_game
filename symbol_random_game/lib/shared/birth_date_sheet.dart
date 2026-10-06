import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:symbol_random_game/core/app_text.dart';
import 'package:symbol_random_game/core/app_theme.dart';

class DateWheelPicker extends StatefulWidget {
  const DateWheelPicker({
    super.key,
    this.initialDate,
    required this.onSelected,
  });

  final DateTime? initialDate;
  final ValueChanged<DateTime> onSelected;

  @override
  State<DateWheelPicker> createState() => _DateWheelPickerState();
}

class _DateWheelPickerState extends State<DateWheelPicker> {
  late int _day;
  late int _month;
  late int _year;

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  static const int _minYear = 1920;
  late final int _maxYear;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _maxYear = now.year;

    final initial =
        widget.initialDate ?? DateTime(now.year - 18, now.month, now.day);

    _year = initial.year.clamp(_minYear, _maxYear);
    _month = initial.month;

    final maxDay = _daysInMonth(_year, _month);

    _day = initial.day.clamp(1, maxDay);

    _dayController = FixedExtentScrollController(initialItem: _day - 1);

    _monthController = FixedExtentScrollController(initialItem: _month - 1);

    _yearController = FixedExtentScrollController(
      initialItem: _year - _minYear,
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _changeDay(int index) {
    setState(() {
      _day = index + 1;
    });
  }

  void _changeMonth(int index) {
    final month = index + 1;
    final maxDay = _daysInMonth(_year, month);

    setState(() {
      _month = month;

      if (_day > maxDay) {
        _day = maxDay;

        _dayController.animateToItem(
          _day - 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _changeYear(int index) {
    final year = _minYear + index;
    final maxDay = _daysInMonth(year, _month);

    setState(() {
      _year = year;

      if (_day > maxDay) {
        _day = maxDay;

        _dayController.animateToItem(
          _day - 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  DateTime get _selectedDate {
    return DateTime(_year, _month, _day);
  }

  void _confirm() {
    HapticFeedback.lightImpact();
    widget.onSelected(_selectedDate);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.30),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildWheels(),
            const SizedBox(height: 18),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FECHA DE NACIMIENTO',
                style: AppText.title(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Selecciona día, mes y año',
                style: AppText.label(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWheels() {
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          Center(
            child: Container(
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildWheel(
                  controller: _dayController,
                  count: _daysInMonth(_year, _month),
                  selectedIndex: _day - 1,
                  onChanged: _changeDay,
                  builder: (index, selected) {
                    final day = index + 1;

                    return _WheelItem(
                      text: day.toString().padLeft(2, '0'),
                      selected: selected,
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildWheel(
                  controller: _monthController,
                  count: 12,
                  selectedIndex: _month - 1,
                  onChanged: _changeMonth,
                  builder: (index, selected) {
                    return _WheelItem(
                      text: _monthName(index + 1),
                      selected: selected,
                    );
                  },
                ),
              ),
              Expanded(
                child: _buildWheel(
                  controller: _yearController,
                  count: _maxYear - _minYear + 1,
                  selectedIndex: _year - _minYear,
                  onChanged: _changeYear,
                  builder: (index, selected) {
                    return _WheelItem(
                      text: (_minYear + index).toString(),
                      selected: selected,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int count,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
    required Widget Function(int index, bool selected) builder,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 52,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.45,
      perspective: 0.0025,
      squeeze: 1.0,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          if (index < 0 || index >= count) {
            return null;
          }

          final selected = index == selectedIndex;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              controller.animateToItem(
                index,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
              );
            },
            child: builder(index, selected),
          );
        },
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: _DateButton(
            label: 'CANCELAR',
            onTap: () {
              Navigator.of(context).pop();
            },
            outlined: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateButton(label: 'CONFIRMAR', onTap: _confirm),
        ),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];

    return months[month - 1];
  }
}

class _WheelItem extends StatelessWidget {
  const _WheelItem({required this.text, required this.selected});

  final String text;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        style: AppText.title(
          color: selected ? Colors.white : Colors.white38,
          fontSize: selected ? 17 : 14,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          letterSpacing: selected ? 0.6 : 0.2,
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(text)),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: outlined ? null : AppColors.primaryGradient,
            color: outlined ? AppColors.primary.withValues(alpha: 0.10) : null,
            borderRadius: BorderRadius.circular(16),
            border: outlined
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.30))
                : null,
          ),
          child: Text(
            label,
            style: AppText.title(
              color: outlined ? Colors.white60 : Colors.white,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
