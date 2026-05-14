import 'package:flutter/material.dart';

class AppColors {
  // --- ANA RENKLER (Marka Kimliği) ---
  // Odaklanmayı artıran modern bir mor/indigo tonu
  static const Color primary = Color(0xFF6C63FF); 
  // Harekete geçirici (FAB ve önemli butonlar için) somon/mercan rengi
  static const Color accent = Color(0xFFFF6584);  

  // --- DARK MODE (Gece Modu) RENKLERİ ---
  // Tam siyah yerine, gözü daha az yoran çok koyu gri
  static const Color backgroundDark = Color(0xFF121212); 
  // Kartlar (Card) ve listeler için bir tık açık gri
  static const Color surfaceDark = Color(0xFF1E1E1E);    
  static const Color textDark = Color(0xFFFFFFFF);
  static const Color textDarkSecondary = Color(0xFFB3B3B3);

  // --- LIGHT MODE (Gündüz Modu) RENKLERİ ---
  static const Color backgroundLight = Color(0xFFF4F6F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF2D3436);
  static const Color textLightSecondary = Color(0xFF636E72);

  // --- DURUM RENKLERİ ---
  static const Color success = Color(0xFF00C853); // Tamamlandı (Yeşil)
  static const Color warning = Color(0xFFFFD600); // Yaklaşıyor (Sarı)
  static const Color error = Color(0xFFFF5252);   // Sınav/Acil (Kırmızı)
  
  // --- DERS ETİKET RENKLERİ (Kullanıcı seçebilsin diye) ---
  static const List<Color> courseColors = [
    Color(0xFF6C63FF), // Mor
    Color(0xFFFF6584), // Mercan
    Color(0xFF00B894), // Nane Yeşili
    Color(0xFF0984E3), // Mavi
    Color(0xFFFAB1A0), // Şeftali
    Color(0xFFFDCB6E), // Hardal
  ];
}