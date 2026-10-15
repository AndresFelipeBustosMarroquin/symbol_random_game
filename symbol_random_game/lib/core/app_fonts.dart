import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFontOption {
  final String name;
  final String family;

  const AppFontOption(this.name, this.family);
}

class AppFonts {
  AppFonts._();

  static const List<AppFontOption> options = [
    AppFontOption('Orbitron', 'Orbitron'),
    AppFontOption('Poppins', 'Poppins'),
    AppFontOption('Montserrat', 'Montserrat'),
    AppFontOption('Playfair Display', 'Playfair Display'),
    AppFontOption('Raleway', 'Raleway'),
    AppFontOption('Lora', 'Lora'),
    AppFontOption('Quicksand', 'Quicksand'),
  ];

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static int get selectedIndex => notifier.value;

  static AppFontOption get current => options[notifier.value];

  static void select(int index) {
    if (index >= 0 && index < options.length) {
      notifier.value = index;
    }
  }

  static TextStyle style(TextStyle base, {int? index}) {
    return GoogleFonts.getFont(
      options[index ?? notifier.value].family,
      textStyle: base,
    );
  }
}

class AppFontBuilder extends StatelessWidget {
  const AppFontBuilder({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppFonts.notifier,
      builder: (context, _, _) => builder(context),
    );
  }
}
