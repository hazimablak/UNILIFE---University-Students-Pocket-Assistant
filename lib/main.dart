import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // BU PAKET ŞART
import 'package:intl/date_symbol_data_local.dart';
import 'package:unilife/core/constants/app_theme.dart';
import 'package:unilife/features/home/screens/main_wrapper.dart'; // MainWrapper importu

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Tarih formatını başlat
  await initializeDateFormatting('tr_TR', null);

  runApp(const UniLifeApp());
}

class UniLifeApp extends StatelessWidget {
  const UniLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniLife',
      debugShowCheckedModeBanner: false,
      
      // Tema Ayarları
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // --- İŞTE EKSİK OLAN VE HATAYI ÇÖZEN KISIM BURASI ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'), // Türkçe
        Locale('en', 'US'), // İngilizce (Yedek)
      ],
      // ----------------------------------------------------

      home: const MainWrapper(),
    );
  }
}