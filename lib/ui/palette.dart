import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours taken from the 1000-ruble note: a muted sea-green on pale paper.
/// Green means "within the limit", deep red means "over" — nothing else is
/// coloured.
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.paper,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.over,
  });

  final Color paper;
  final Color ink;
  final Color muted;
  final Color line;
  final Color accent;
  final Color accentSoft;
  final Color over;

  static const light = Palette(
    paper: Color(0xFFEEF2EF),
    ink: Color(0xFF18211F),
    muted: Color(0xFF5E6A66),
    line: Color(0xFFD3DCD8),
    accent: Color(0xFF1F6F64),
    accentSoft: Color(0xFF9FD0C1),
    over: Color(0xFFB0273C),
  );

  static const dark = Palette(
    paper: Color(0xFF111715),
    ink: Color(0xFFE5EEEA),
    muted: Color(0xFF93A29C),
    line: Color(0xFF26302D),
    accent: Color(0xFF63C2AE),
    accentSoft: Color(0xFF2E5C52),
    over: Color(0xFFF07A8A),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension PaletteOf on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}

ThemeData buildTheme(Palette p, Brightness brightness) {
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  // The font family name alone keeps the theme on Flutter's own TextTheme.
  final family = GoogleFonts.wixMadeforDisplay().fontFamily;
  final text = base.textTheme.apply(fontFamily: family, bodyColor: p.ink, displayColor: p.ink);
  return base.copyWith(
    scaffoldBackgroundColor: p.paper,
    colorScheme: ColorScheme.fromSeed(seedColor: p.accent, brightness: brightness, surface: p.paper),
    textTheme: text,
    extensions: [p],
    dividerColor: p.line,
    inputDecorationTheme: InputDecorationTheme(
      border: UnderlineInputBorder(borderSide: BorderSide(color: p.line, width: 1.5)),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.line, width: 1.5)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: p.ink, width: 2)),
      labelStyle: TextStyle(color: p.muted),
      floatingLabelStyle: TextStyle(color: p.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.ink,
        foregroundColor: p.paper,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.wixMadeforDisplay(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(backgroundColor: p.ink, contentTextStyle: TextStyle(color: p.paper), behavior: SnackBarBehavior.floating),
  );
}
