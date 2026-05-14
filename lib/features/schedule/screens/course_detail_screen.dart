import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unilife/core/constants/app_colors.dart';
import 'package:unilife/core/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> courseData;

  const CourseDetailScreen({super.key, required this.courseData});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _absentCount = 0; // Devamsızlık sayısı
  List<Map<String, dynamic>> _courseTasks = []; // Bu derse ait görevler

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 Sekme: Görevler, Notlar
    _loadAbsentCount();
    _loadCourseTasks();
  }

  // Devamsızlığı Hafızadan Çek
  Future<void> _loadAbsentCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 'id' yerine 'course_id' kullanıyoruz
      _absentCount = prefs.getInt('absent_${widget.courseData['course_id']}') ?? 0;
    });
  }

  // Devamsızlığı Güncelle (DÜZELTİLDİ: course_id kullanıldı)
  Future<void> _updateAbsent(int change) async {
    final newCount = _absentCount + change;
    if (newCount < 0) return;

    final prefs = await SharedPreferences.getInstance();
    // 'id' yerine 'course_id' kullanıyoruz
    await prefs.setInt('absent_${widget.courseData['course_id']}', newCount);
    setState(() {
      _absentCount = newCount;
    });
  }

  // Bu Derse Ait Ödev ve Sınavları Çek (DÜZELTİLDİ: course_id kullanıldı)
  Future<void> _loadCourseTasks() async {
    final db = DatabaseHelper();
    final tasks = await db.rawQuery('''
      SELECT * FROM tasks 
      WHERE course_id = ? 
      ORDER BY due_date ASC
    ''', [widget.courseData['course_id']]); // <-- İŞTE BURASI DEĞİŞTİ
    
    setState(() {
      _courseTasks = tasks;
    });
  }

  // Renk Kodu Çevirici
  Color _parseColor(String? code) {
    if (code == null) return AppColors.primary;
    try {
      return Color(int.parse(code.replaceAll('#', ''), radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gelen verideki ID'yi kontrol et (Hata önleyici)
    final color = _parseColor(widget.courseData['color_code']);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseData['name'] ?? "Ders Detayı"),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. DERS BİLGİ KARTI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color,
                  child: Text(
                    widget.courseData['name'] != null ? widget.courseData['name'][0].toUpperCase() : "?",
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Text(widget.courseData['name'] ?? "", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(widget.courseData['instructor'] ?? "Hoca Bilgisi Yok", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
                  child: Text("📍 ${widget.courseData['room_name'] ?? 'Sınıf Yok'}", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. DEVAMSIZLIK SAYACI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Devamsızlık:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => _updateAbsent(-1), icon: const Icon(Icons.remove, color: Colors.red)),
                      Text("$_absentCount", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => _updateAbsent(1), icon: const Icon(Icons.add, color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. SEKMELER (TAB BAR)
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: "Görevler & Sınavlar"),
              Tab(text: "Notlar"), // İleride not sistemi eklersek burası dolacak
            ],
          ),

          // 4. SEKME İÇERİKLERİ
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // GÖREVLER LİSTESİ
                _courseTasks.isEmpty
                    ? const Center(child: Text("Bu ders için kayıtlı ödev/sınav yok."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _courseTasks.length,
                        itemBuilder: (context, index) {
                          final task = _courseTasks[index];
                          final isExam = task['type'] == 'EXAM';
                          DateTime date;
                          try {
                            date = task['due_date'] is int 
                              ? DateTime.fromMillisecondsSinceEpoch(task['due_date'])
                              : DateTime.parse(task['due_date']);
                          } catch (e) {
                            date = DateTime.now();
                          }

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                            child: ListTile(
                              leading: Icon(
                                isExam ? Icons.timer : Icons.book, 
                                color: isExam ? Colors.red : AppColors.primary
                              ),
                              title: Text(task['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(DateFormat('d MMMM yyyy', 'tr_TR').format(date)),
                              trailing: task['is_completed'] == 1 
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.circle_outlined, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                
                // NOTLAR (Şimdilik Boş)
                const Center(child: Text("Ders notları özelliği yakında eklenecek! 📝")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}