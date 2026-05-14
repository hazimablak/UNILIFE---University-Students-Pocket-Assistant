import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:unilife/core/constants/app_colors.dart';
import 'package:unilife/core/database/database_helper.dart';
import 'package:unilife/features/home/widgets/active_course_card.dart';
import 'package:unilife/features/schedule/screens/add_course_screen.dart';
import 'package:unilife/features/tasks/screens/add_task_screen.dart';
import 'package:unilife/features/home/screens/study_timer_screen.dart';
import 'package:unilife/features/profile/screens/profile_screen.dart';
import 'dart:io'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- KULLANICI BİLGİLERİ ---
  String _userName = "Öğrenci";
  String? _profileImagePath;
  
  // --- ÇALIŞMA İSTATİSTİKLERİ ---
  int _dailyGoalMinutes = 60;
  int _studiedMinutes = 0;

  // --- LİSTELER ---
  List<Map<String, dynamic>> _upcomingExams = [];
  List<Map<String, dynamic>> _upcomingHomeworks = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadUserData();
    await _loadStudyStats();
    await _loadTasks();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "Öğrenci";
      _profileImagePath = prefs.getString('profileImage');
    });
  }

  Future<void> _loadStudyStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studiedMinutes = prefs.getInt('todayStudyTime') ?? 0; 
    });
  }

  Future<void> _loadTasks() async {
    final db = DatabaseHelper();
    
    final exams = await db.rawQuery('''
      SELECT t.*, c.name as course_name 
      FROM tasks t 
      LEFT JOIN courses c ON t.course_id = c.id
      WHERE t.type = 'EXAM' AND t.is_completed = 0 
      ORDER BY t.due_date ASC LIMIT 5
    ''');

    final homeworks = await db.rawQuery('''
      SELECT t.*, c.name as course_name 
      FROM tasks t 
      LEFT JOIN courses c ON t.course_id = c.id
      WHERE t.type = 'HOMEWORK' AND t.is_completed = 0 
      ORDER BY t.due_date ASC LIMIT 3
    ''');

    setState(() {
      _upcomingExams = exams;
      _upcomingHomeworks = homeworks;
    });
  }

  // --- HATA ÇÖZEN AKILLI TARİH FONKSİYONU ---
  DateTime _parseDate(dynamic dateInput) {
    if (dateInput is int) {
      // Eğer sayı olarak kayıtlıysa (Milisaniye)
      return DateTime.fromMillisecondsSinceEpoch(dateInput);
    } else if (dateInput is String) {
      // Eğer yazı olarak kayıtlıysa
      return DateTime.parse(dateInput);
    }
    // Hiçbiri değilse şu anı döndür (Hata vermesin)
    return DateTime.now();
  }
  // ------------------------------------------

  

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImage', image.path);
      setState(() => _profileImagePath = image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('d MMMM EEEE', 'tr_TR').format(DateTime.now());
    double progress = (_studiedMinutes / _dailyGoalMinutes).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAllData,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. ÜST BAŞLIK
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // Profil ekranına git ve dönünce anasayfayı yenile (isim/foto değişmiş olabilir)
                          await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                          _loadAllData();
                        },
                        child: Row(
                          children: [
                            Text("Merhaba, $_userName", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(formattedDate, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    ],
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        image: _profileImagePath != null
                            ? DecorationImage(image: FileImage(File(_profileImagePath!)), fit: BoxFit.cover)
                            : const DecorationImage(image: NetworkImage("https://i.pravatar.cc/150?img=12"), fit: BoxFit.cover),
                      ),
                      child: _profileImagePath == null ? const Align(alignment: Alignment.bottomRight, child: Icon(Icons.add_a_photo, size: 16, color: AppColors.primary)) : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 25),

              // 2. GÜNLÜK ÇALIŞMA HEDEFİ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Günlük Hedef", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("$_studiedMinutes / $_dailyGoalMinutes dk", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: progress >= 1.0 ? Colors.green : AppColors.primary,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // 3. AKTİF DERS KARTI
              const ActiveCourseCard(),

              const SizedBox(height: 25),

              // 4. YAKLAŞAN SINAVLAR
              if (_upcomingExams.isNotEmpty) ...[
                const Text("Yaklaşan Sınavlar 🚨", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _upcomingExams.length,
                    itemBuilder: (context, index) {
                      final exam = _upcomingExams[index];
                      // GÜNCELLENEN KISIM: _parseDate kullanıyoruz
                      final date = _parseDate(exam['due_date']); 
                      final daysLeft = date.difference(DateTime.now()).inDays;
                      
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                daysLeft <= 0 ? "BUGÜN" : "$daysLeft gün kaldı",
                                style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              exam['title'],
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              exam['course_name'] ?? "Genel",
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 25),
              ],

              // 5. YAKLAŞAN ÖDEVLER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Yaklaşan Ödevler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_upcomingHomeworks.isNotEmpty)
                    TextButton(onPressed: () {}, child: const Text("Tümünü Gör")),
                ],
              ),
              
              if (_upcomingHomeworks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.check_circle_outline, color: AppColors.accent),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Ödevlerin Tamam! 🎉", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("Şimdilik yapman gereken bir ödev yok.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._upcomingHomeworks.map((task) {
                  // GÜNCELLENEN KISIM: _parseDate kullanıyoruz
                  final date = _parseDate(task['due_date']);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      leading: const Icon(Icons.book, color: AppColors.primary),
                      title: Text(task['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${task['course_name'] ?? 'Ders Yok'} • ${DateFormat('d MMM', 'tr_TR').format(date)}"),
                      trailing: Checkbox(
                        value: task['is_completed'] == 1,
                        activeColor: AppColors.primary,
                        onChanged: (val) async {
                          final db = DatabaseHelper();
                          await db.update('tasks', {'id': task['id'], 'is_completed': 1});
                          _loadAllData();
                        },
                      ),
                    ),
                  );
                }).toList(),
              
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickMenu(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showQuickMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const Text("Hızlı Ekle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.book, color: AppColors.primary),
                  title: const Text("Ders Ekle"),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCourseScreen()));
                    _loadAllData();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.task, color: AppColors.accent),
                  title: const Text("Ödev / Sınav Ekle"),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTaskScreen()));
                    _loadAllData();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.timer, color: Colors.orange),
                  title: const Text("Çalışma Başlat"),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const StudyTimerScreen()));
                    // Döndüğü an verileri yenile
                    _loadAllData();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}