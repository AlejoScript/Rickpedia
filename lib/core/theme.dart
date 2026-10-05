import 'package:flutter/material.dart';

// ─── Colores: toda la paleta vive aquí ──────────────────────────
class C {
  static const bg = Color(0xFF08080C); // fondo principal
  static const card = Color(0xFF111119); // tarjetas
  static const card2 = Color(0xFF1A1A26); // variante
  static const neon = Color(0xFF39FF14); // acento: activos y favoritos
  static const text = Color(0xFFFFFFFF);
  static const muted = Color(0xFFA0A0B0); // texto secundario
  static const dim = Color(0xFF606070); // deshabilitado
  static const line = Color(0xFF2A2A3A); // bordes
  static const red = Color(0xFFFF6B6B);
}

// ─── Textos: Outfit = títulos, Geist = funcional ────────────────
class T {
  static const logo = TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w900,
    fontSize: 48,
    letterSpacing: -1,
    color: C.neon,
  );
  static const appBar = TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w800,
    fontSize: 22,
    color: Colors.white,
  );
  static const title = TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w800,
    fontSize: 26,
    color: Colors.white,
  );
  static const name = TextStyle(
    fontFamily: 'Outfit',
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: Colors.white,
  );
  static const body = TextStyle(
    fontFamily: 'Geist',
    fontSize: 14,
    color: C.muted,
  );
  static const strong = TextStyle(
    fontFamily: 'Geist',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: Colors.white,
  );
  static const label = TextStyle(
    fontFamily: 'Geist',
    fontWeight: FontWeight.w600,
    fontSize: 11,
    letterSpacing: 1.2,
    color: C.dim,
  );
  static const caption = TextStyle(
    fontFamily: 'Geist',
    fontSize: 12,
    color: C.muted,
  );
}

// ─── Medidas compartidas ────────────────────────────────────────
class D {
  static const pad = 20.0;
  static const radius = 16.0;
  static const bigRadius = 20.0;
  static const navH = 76.0;
}

// ─── Tema oscuro de la app ──────────────────────────────────────
ThemeData appTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(primary: C.neon, surface: C.card),
    scaffoldBackgroundColor: C.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      foregroundColor: C.text,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.card,
      hintStyle: const TextStyle(color: C.dim, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: C.neon, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.neon),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: C.card2,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
