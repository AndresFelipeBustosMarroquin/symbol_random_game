import 'package:flutter/widgets.dart';

const desktopLayoutBreakpoint = 900.0;

bool isDesktopLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= desktopLayoutBreakpoint;
