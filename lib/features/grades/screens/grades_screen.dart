import 'package:flutter/material.dart';
import 'package:unilife/core/constants/app_colors.dart';
import 'package:unilife/core/database/database_helper.dart';
import 'package:unilife/features/schedule/models/course_model.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  List<Course> _courses = [];
  // Notları hafızada tutmak için basit bir yapı: {courseId: [{'name': 'Vize', 'score': 70, 'weight': 40}]}
  Map<int, List<Map<String, dynamic>>> _courseGrades = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper();
    
    // 1. Dersleri Çek
    final courseData = await db.queryAllRows('courses');
    _courses = courseData.map((e) => Course.fromMap(e)).toList();

    // 2. Notları Çek ve Eşleştir
    final gradesData = await db.queryAllRows('grades');
    
    _courseGrades.clear();
    for (var grade in gradesData) {
      final cId = grade['course_id'];
      if (!_courseGrades.containsKey(cId)) {
        _courseGrades[cId] = [];
      }
      _courseGrades[cId]!.add(grade);
    }

    setState(() {});
  }

  // Ortalama Hesaplama (Vize %40 + Final %60 gibi)
  double _calculateAverage(int courseId) {
    final grades = _courseGrades[courseId];
    if (grades == null || grades.isEmpty) return 0.0;

    double totalScore = 0;
    double totalWeight = 0;

    for (var g in grades) {
      totalScore += (g['score'] as double) * (g['weight'] as double);
      totalWeight += (g['weight'] as double);
    }

    if (totalWeight == 0) return 0.0;
    return totalScore / totalWeight; // Ağırlıklı Ortalama
  }

  // Harf Notu Tahmini
  String _getLetterGrade(double average) {
    if (average >= 90) return "AA";
    if (average >= 85) return "BA";
    if (average >= 80) return "BB";
    if (average >= 75) return "CB";
    if (average >= 70) return "CC";
    if (average >= 60) return "DC";
    if (average >= 50) return "DD";
    return "FF";
  }

  // --- NOT EKLEME PENCERESİ ---
  void _showAddGradeDialog(Course course) {
    final nameController = TextEditingController();
    final scoreController = TextEditingController();
    final weightController = TextEditingController(text: "40"); // Varsayılan %40

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${course.name} Notu Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Sınav Adı (Vize, Final, Quiz)"),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Not (0-100)"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Etki % (Örn: 40)"),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && scoreController.text.isNotEmpty) {
                await DatabaseHelper().insert('grades', {
                  'course_id': course.id,
                  'name': nameController.text,
                  'score': double.tryParse(scoreController.text) ?? 0.0,
                  'weight': double.tryParse(weightController.text) ?? 0.0,
                });
                Navigator.pop(context);
                _loadData(); // Listeyi yenile
              }
            },
            child: const Text("Kaydet"),
          )
        ],
      ),
    );
  }

  // Not Silme
  Future<void> _deleteGrade(int id) async {
    await DatabaseHelper().delete('grades', id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notlar & Ortalama")),
      body: _courses.isEmpty
          ? const Center(child: Text("Henüz ders eklenmemiş."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                final grades = _courseGrades[course.id] ?? [];
                final average = _calculateAverage(course.id!);
                final letter = _getLetterGrade(average);
                final color = Color(int.parse(course.colorCode, radix: 16));

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
  leading: Container(
    width: 45, height: 45,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
      ]
    ),
    child: Text(
      letter, 
      style: const TextStyle(
        color: Colors.white, 
        fontWeight: FontWeight.bold,
        fontSize: 16
      )
    ),
  ),
  title: Text(course.name, style: const TextStyle(fontWeight: FontWeight.bold)),
  subtitle: Text("Ortalama: ${average.toStringAsFixed(1)}"),
  trailing: IconButton(
    icon: const Icon(Icons.add_circle, color: AppColors.primary),
    onPressed: () => _showAddGradeDialog(course),
  ),
  children: [
    // --- DÜZELTİLEN KISIM BURASI ---
    if (grades.isEmpty)
      const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_upward, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text("Henüz not girilmedi. + butonuna bas.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
    else
      ...grades.map((g) => ListTile(
        title: Text(g['name']),
        subtitle: Text("Etki: %${g['weight'].toInt()}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${g['score'].toInt()}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: g['score'] < 50 ? Colors.red : Colors.green)),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () => _deleteGrade(g['id']))
          ],
        ),
      )),
  ],
),
                );
              },
            ),
    );
  }
}