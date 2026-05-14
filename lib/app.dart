import 'package:flutter/material.dart';
import 'core/constants/app_theme.dart';
// HomeScreen yerine MainWrapper import et
import 'features/home/screens/main_wrapper.dart'; 

class UniLifeApp extends StatelessWidget {
  const UniLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // ARTIK BURASI DEĞİŞTİ:
      home: const MainWrapper(), 
    );
  }
}