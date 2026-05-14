import 'package:flutter/material.dart';
import 'package:unilife/core/constants/app_colors.dart';
import 'package:unilife/core/database/database_helper.dart';
import 'package:unilife/features/schedule/screens/add_course_screen.dart';
import 'package:unilife/features/schedule/screens/course_detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final int _todayIndex = DateTime.now().weekday - 1;
  final List<String> _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  // Dersleri Çek (ID dahil)
  Future<List<Map<String, dynamic>>> _getClassesForDay(int dayIndex) async {
    final db = DatabaseHelper();
    return await db.rawQuery('''
      SELECT s.id, s.course_id, s.start_time, s.end_time, c.name, c.room_name, c.instructor, c.color_code
      FROM schedules s
      JOIN courses c ON s.course_id = c.id
      WHERE s.day_of_week = ?
      ORDER BY s.start_time ASC
    ''', [dayIndex + 1]); 
  }

  Color _parseColor(String? code) {
    if(code == null) return AppColors.primary;
    try {
      return Color(int.parse(code.replaceAll('#', ''), radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      initialIndex: _todayIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Haftalık Program"),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: _days.map((day) => Tab(text: day)).toList(),
          ),
        ),
        body: TabBarView(
          children: List.generate(7, (index) => _buildDayPage(index)),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCourseScreen()));
            setState(() {});
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDayPage(int dayIndex) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getClassesForDay(dayIndex),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final classes = snapshot.data!;
        
        if (classes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wb_sunny_outlined, size: 80, color: Colors.orange.withOpacity(0.5)),
                const SizedBox(height: 16),
                const Text("Bugün ders yok!\nKeyfine bak. 😎", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final lesson = classes[index];
            final color = _parseColor(lesson['color_code']);

            // SİLME ÖZELLİĞİ İÇİN INKWELL
            return InkWell(
              onTap: () {
                // CourseDetailScreen'e giderken ders verilerini gönderiyoruz
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseDetailScreen(courseData: lesson),
                  ),
                );
              },
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Dersi Sil?"),
                    content: Text("${lesson['name']} dersini programdan kaldırmak istiyor musun?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
                      TextButton(
                        onPressed: () async {
                          await DatabaseHelper().delete('schedules', lesson['id']);
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: const Text("Sil", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Text(lesson['start_time'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(lesson['end_time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border(left: BorderSide(color: color, width: 4)),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lesson['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                Text(lesson['room_name'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}