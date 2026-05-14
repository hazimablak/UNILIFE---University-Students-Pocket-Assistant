import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Klavye formatı için gerekli
import 'package:intl/intl.dart';
import 'package:unilife/core/constants/app_colors.dart';
import 'package:unilife/core/database/database_helper.dart';
import 'package:unilife/features/schedule/models/course_model.dart';
import 'package:unilife/features/tasks/models/task_model.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController(); 
  
  Course? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'HOMEWORK'; 
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
    // Başlangıçta bugünün tarihini "18.12.2025" formatında yazalım
    _dateController.text = DateFormat('dd.MM.yyyy').format(_selectedDate);
  }

  Future<void> _loadCourses() async {
    final data = await DatabaseHelper().queryAllRows('courses');
    setState(() {
      _courses = data.map((e) => Course.fromMap(e)).toList();
      if (_courses.isNotEmpty) {
        _selectedCourse = _courses[0];
      }
    });
  }

  // --- TAKVİMDEN SEÇME ---
  Future<void> _pickDate() async {
    // Klavyeyi kapat
    FocusScope.of(context).requestFocus(FocusNode());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      // --- İŞTE BURASI DEĞİŞTİ: ARTIK GEÇMİŞ SEÇİLEMEZ ---
      firstDate: DateTime.now(), 
      lastDate: DateTime(2030),
      locale: const Locale('tr', 'TR'),
      initialEntryMode: DatePickerEntryMode.calendarOnly, // Takvim olarak açılsın
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Seçilen tarihi kutuya noktalı formatta yaz
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  // --- KAYDETME ---
  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir başlık girin')));
      return;
    }

    try {
      // Kutudaki metni tarihe çevir
      DateTime parsedDate = DateFormat('dd.MM.yyyy').parse(_dateController.text);
      
      // Geçmiş tarih kontrolü (Elle yazarsa diye güvenlik)
      // (Saat farkını yok saymak için gün bazında karşılaştırma yapıyoruz)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (parsedDate.isBefore(today)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçmişe dönük görev ekleyemezsin!')),
        );
        return;
      }

      final newTask = Task(
        courseId: _selectedCourse?.id,
        title: _titleController.text,
        type: _selectedType,
        dueDate: parsedDate,
        isCompleted: false,
      );

      await DatabaseHelper().insert('tasks', newTask.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Görev Eklendi!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir tarih girin (Gün.Ay.Yıl)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Görev Ekle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TÜR SEÇİMİ
            Row(
              children: [
                Expanded(child: _buildTypeSelector("Ödev", "HOMEWORK", Icons.book)),
                const SizedBox(width: 15),
                Expanded(child: _buildTypeSelector("Sınav", "EXAM", Icons.timer)),
              ],
            ),
            const SizedBox(height: 25),

            // BAŞLIK
            const Text("Başlık", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "Örn: Sayfa 102-105 özeti",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // DERS SEÇİMİ
            const Text("Hangi Ders?", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Course>(
                  value: _selectedCourse,
                  isExpanded: true,
                  hint: const Text("Ders Seçin"),
                  items: _courses.map((Course course) {
                    return DropdownMenuItem<Course>(
                      value: course,
                      child: Text(course.name),
                    );
                  }).toList(),
                  onChanged: (Course? newValue) {
                    setState(() => _selectedCourse = newValue);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- AKILLI TARİH ALANI ---
            const Text("Teslim / Sınav Tarihi", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dateController,
              keyboardType: TextInputType.number, 
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, 
                LengthLimitingTextInputFormatter(8), 
                DateInputFormatter(), // SİHİRLİ NOKTA FORMATLAYICI
              ],
              decoration: InputDecoration(
                hintText: "GG.AA.YYYY",
                helperText: "Elle yazabilir veya takvimden seçebilirsin",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today, color: AppColors.primary),
                  onPressed: _pickDate,
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // KAYDET BUTONU
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text("Görevi Kaydet", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(String label, String value, IconData icon) {
    bool isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SİHİRLİ FORMATLAYICI (OTOMATİK NOKTA) ---
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;

    var text = newValue.text;
    var buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex <= 4 && nonZeroIndex % 2 == 0 && nonZeroIndex != text.length) {
        buffer.write('.');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}