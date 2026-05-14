import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unilife/core/constants/app_colors.dart';
import 'package:unilife/core/database/database_helper.dart';
import 'package:unilife/features/tasks/screens/add_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // LİSTELER
  List<Map<String, dynamic>> _homeworks = [];
  List<Map<String, dynamic>> _exams = [];

  // FİLTRE DURUMU (Varsayılan: Tamamlananları Göster)
  bool _hideCompleted = false; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }

  // Verileri Çek ve Filtrele
  Future<void> _loadTasks() async {
    final db = DatabaseHelper();
    
    // Filtre açıksa sadece tamamlanmayanları (0), kapalıysa hepsini çek
    String filterClause = _hideCompleted ? "AND t.is_completed = 0" : "";

    // Ödevler
    final homeworkData = await db.rawQuery('''
      SELECT t.*, c.name as course_name 
      FROM tasks t 
      LEFT JOIN courses c ON t.course_id = c.id
      WHERE t.type = 'HOMEWORK' $filterClause
      ORDER BY t.due_date ASC
    ''');

    // Sınavlar
    final examData = await db.rawQuery('''
      SELECT t.*, c.name as course_name 
      FROM tasks t 
      LEFT JOIN courses c ON t.course_id = c.id
      WHERE t.type = 'EXAM' $filterClause
      ORDER BY t.due_date ASC
    ''');

    setState(() {
      _homeworks = homeworkData;
      _exams = examData;
    });
  }

  // Tarih Formatlayıcı (Sayı/Yazı Sorununu Çözen)
  DateTime _parseDate(dynamic dateInput) {
    if (dateInput is int) return DateTime.fromMillisecondsSinceEpoch(dateInput);
    if (dateInput is String) return DateTime.parse(dateInput);
    return DateTime.now();
  }

  // --- GERİ SAYIM HESAPLAYICI ---
  String _getCountdownText(DateTime date) {
    final now = DateTime.now();
    // Saat farkını yok saymak için sadece günleri karşılaştırıyoruz
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    
    final diff = target.difference(today).inDays;

    if (diff < 0) return "Süresi Geçti";
    if (diff == 0) return "BUGÜN";
    if (diff == 1) return "YARIN";
    return "$diff gün kaldı";
  }

  // Geri Sayım Rengi (Aciliyete göre)
  Color _getCountdownColor(DateTime date) {
    final diff = date.difference(DateTime.now()).inDays;
    if (diff < 0) return Colors.grey; // Geçmiş
    if (diff <= 2) return Colors.red; // Çok Acil
    if (diff <= 5) return Colors.orange; // Yaklaşıyor
    return Colors.green; // Vakit var
  }

  // Görev Tamamlama İşlemi
  Future<void> _toggleTaskStatus(int id, int currentStatus) async {
    final db = DatabaseHelper();
    await db.update('tasks', {'id': id, 'is_completed': currentStatus == 1 ? 0 : 1});
    _loadTasks(); // Listeyi yenile
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Görevler"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Ödevler"),
            Tab(text: "Sınavlar"),
          ],
        ),
        actions: [
          // --- FİLTRE BUTONU ---
          IconButton(
            icon: Icon(_hideCompleted ? Icons.filter_list_off : Icons.filter_list),
            tooltip: _hideCompleted ? "Tümünü Göster" : "Tamamlananları Gizle",
            onPressed: () {
              setState(() {
                _hideCompleted = !_hideCompleted;
              });
              _loadTasks(); // Filtre değişince verileri tekrar çek
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_hideCompleted ? "Tamamlananlar gizlendi" : "Tüm görevler gösteriliyor"),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(_homeworks, isExam: false),
          _buildTaskList(_exams, isExam: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTaskScreen()));
          _loadTasks();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks, {required bool isExam}) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 80, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 10),
            Text(
              _hideCompleted ? "Yapılacak görev yok! 🎉" : "Henüz görev eklenmemiş.",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final date = _parseDate(task['due_date']);
        final isCompleted = task['is_completed'] == 1;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              // İKON (Sınavsa Saat, Ödevse Kitap)
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isExam ? Colors.red : AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExam ? Icons.timer : Icons.book,
                  color: isExam ? Colors.red : AppColors.primary,
                ),
              ),
              
              title: Text(
                task['title'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isCompleted ? TextDecoration.lineThrough : null, // Tamamlandıysa üzerini çiz
                  color: isCompleted ? Colors.grey : null,
                ),
              ),
              
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("${task['course_name'] ?? 'Genel'}"),
                  const SizedBox(height: 6),
                  
                  // --- GERİ SAYIM CHIP (ETİKETİ) ---
                  if (!isCompleted) 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCountdownColor(date).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _getCountdownColor(date).withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 12, color: _getCountdownColor(date)),
                          const SizedBox(width: 4),
                          Text(
                            "${DateFormat('d MMM', 'tr_TR').format(date)} • ${_getCountdownText(date)}",
                            style: TextStyle(
                              color: _getCountdownColor(date),
                              fontSize: 12,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              trailing: Checkbox(
                value: isCompleted,
                activeColor: isExam ? Colors.red : AppColors.primary,
                onChanged: (val) => _toggleTaskStatus(task['id'], task['is_completed']),
              ),
            ),
          ),
        );
      },
    );
  }
}