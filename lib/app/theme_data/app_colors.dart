import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Forest Green Palette ───────────────────────────────────────────────────
  static const Color forest1 = Color(0xFFDAF1DE); // Lightest — mint white
  static const Color forest2 = Color(0xFF8EB69B); // Light — sage green
  static const Color forest3 = Color(0xFF235347); // Mid — forest green
  static const Color forest4 = Color(0xFF163832); // Dark — deep forest
  static const Color forest5 = Color(0xFF0B2B26); // Darker
  static const Color forest6 = Color(0xFF051F20); // Darkest — near black

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = forest2;
  static const Color primaryLight = forest1;
  static const Color primaryDark = forest3;
  static const Color accent = forest1;

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color background = forest6;
  static const Color surface = forest5;
  static const Color surfaceLight = forest4;

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textDark = Colors.white; // headings / primary text
  static const Color textBody = forest1; // body / secondary text
  static const Color textMuted = forest2; // muted / placeholder
  static const Color textHint = forest2; // kept for backward compat

  // ── Borders / Dividers ─────────────────────────────────────────────────────
  static const Color inputBorder = forest3;
  static const Color divider = forest3;

  // ── Misc ───────────────────────────────────────────────────────────────────
  static const Color white = Colors.white;

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFF6B6B);
}
