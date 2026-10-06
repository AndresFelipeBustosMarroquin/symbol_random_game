import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFontOption {
  final String name;
  final String family; // nombre exacto en Google Fonts

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

  /// Índice de la fuente seleccionada. Cambiarlo notifica a todos los
  /// [AppFontBuilder] para que se reconstruyan con la nueva fuente.
  /// (Para arrancar con Orbitron, el look original del juego, usa 2.)
  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  static int get selectedIndex => notifier.value;

  static AppFontOption get current => options[notifier.value];

  static void select(int index) {
    if (index >= 0 && index < options.length) {
      notifier.value = index;
    }
  }

  /// Aplica la fuente (la seleccionada o la del [index]) a un estilo base.
  static TextStyle style(TextStyle base, {int? index}) {
    return GoogleFonts.getFont(
      options[index ?? notifier.value].family,
      textStyle: base,
    );
  }
}

/// Reconstruye su contenido cada vez que cambia la fuente seleccionada.
///
/// Úsalo para envolver pantallas completas y también widgets `const`
/// que contengan texto con [AppText], porque Flutter no reconstruye
/// los widgets `const` cuando se reconstruye su padre.
class AppFontBuilder extends StatelessWidget {
  const AppFontBuilder({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppFonts.notifier,
      builder: (context, _, __) => builder(context),
    );
  }
}
