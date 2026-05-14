import 'package:flutter/material.dart';
import 'package:unilife/core/constants/app_colors.dart';
import 'package:unilife/features/home/screens/home_screen.dart';
import 'package:unilife/features/schedule/screens/schedule_screen.dart';
import 'package:unilife/features/tasks/screens/tasks_screen.dart';
import 'package:unilife/features/grades/screens/grades_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0; // Şu an hangi sekmedeyiz? (0: Home)

  // Ekran Listesi
  final List<Widget> _screens = [
    const HomeScreen(),
    const ScheduleScreen(),
    const TasksScreen(),
    const GradesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Seçili ekranı göster
      body: _screens[_currentIndex],
      
      // Alt Menü Tasarımı
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        indicatorColor: AppColors.primary.withOpacity(0.2), // Seçili butonun arkasındaki hafif morluk
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Bugün',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
            label: 'Program',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt, color: AppColors.primary),
            label: 'Görevler',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart, color: AppColors.primary),
            label: 'Notlar',
          ),
        ],
      ),
    );
  }
}