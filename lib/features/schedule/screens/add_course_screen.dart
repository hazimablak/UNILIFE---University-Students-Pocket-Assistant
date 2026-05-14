import 'package:flutter/material.dart';
import 'package:unilife/core/constants/app_colors.dart';
import 'package:unilife/core/database/database_helper.dart';
import 'package:unilife/features/schedule/models/course_model.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instructorController = TextEditingController();
  final _roomController = TextEditingController();
  
  String _selectedColorCode = AppColors.courseColors[0].value.toRadixString(16);

  // Eklenen Ders Saatlerini Tutacak Liste
  // Örn: [{'day': 1, 'start': '10:00', 'end': '11:00'}, ...]
  final List<Map<String, dynamic>> _addedSchedules = [];

  final List<String> _days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  // --- SAAT EKLEME PENCERESİ ---
  void _showAddScheduleDialog() {
    int selectedDayIndex = 0; // 0: Pazartesi
    TimeOfDay startTime = const TimeOfDay(hour: 09, minute: 00);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 30);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Dialog içinde ekranı yenilemek için
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Ders Saati Ekle"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Gün Seçimi
                  DropdownButton<int>(
                    value: selectedDayIndex,
                    isExpanded: true,
                    items: List.generate(7, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text(_days[index]),
                      );
                    }),
                    onChanged: (val) {
                      setDialogState(() => selectedDayIndex = val!);
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Saat Seçimi (Başlangıç - Bitiş)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTimePickerButton(context, "Başlangıç", startTime, (val) {
                        setDialogState(() => startTime = val);
                      }),
                      const Text("-"),
                      _buildTimePickerButton(context, "Bitiş", endTime, (val) {
                        setDialogState(() => endTime = val);
                      }),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Listeye Ekle
                    setState(() {
                      _addedSchedules.add({
                        'day': selectedDayIndex + 1, // Veritabanı için 1'den başlatıyoruz
                        'start': "${startTime.hour.toString().padLeft(2,'0')}:${startTime.minute.toString().padLeft(2,'0')}",
                        'end': "${endTime.hour.toString().padLeft(2,'0')}:${endTime.minute.toString().padLeft(2,'0')}",
                        'dayName': _days[selectedDayIndex], // Ekranda göstermek için
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Ekle"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Yardımcı Saat Butonu
  Widget _buildTimePickerButton(BuildContext context, String label, TimeOfDay time, Function(TimeOfDay) onPicked) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        TextButton(
          onPressed: () async {
            final picked = await showTimePicker(context: context, initialTime: time);
            if (picked != null) onPicked(picked);
          },
          child: Text(
            "${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // --- KAYDETME İŞLEMİ (GÜNCELLENDİ) ---
  Future<void> _saveCourse() async {
    if (_formKey.currentState!.validate()) {
      final db = DatabaseHelper();

      // 1. Önce Dersi Kaydet
      final newCourse = Course(
        name: _nameController.text,
        instructor: _instructorController.text,
        roomName: _roomController.text,
        colorCode: _selectedColorCode,
      );
      
      // insert fonksiyonu bize eklenen dersin ID'sini geri döner
      int courseId = await db.insert('courses', newCourse.toMap());

      // 2. Şimdi Saatleri Kaydet (Varsa)
      for (var schedule in _addedSchedules) {
        await db.insert('schedules', {
          'course_id': courseId,
          'day_of_week': schedule['day'], // 1: Pzt
          'start_time': schedule['start'],
          'end_time': schedule['end'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ders ve Program Kaydedildi!')));
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Ders Ekle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- FORM ALANLARI (AYNI KALDI) ---
              const Text("Ders Adı", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: "Örn: Diferansiyel Denklemler", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _instructorController,
                      decoration: const InputDecoration(labelText: "Hoca", border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _roomController,
                      decoration: const InputDecoration(labelText: "Sınıf", border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- RENK SEÇİMİ (AYNI) ---
              const Text("Renk Seç", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppColors.courseColors.length,
                  itemBuilder: (context, index) {
                    final color = AppColors.courseColors[index];
                    final code = color.value.toRadixString(16);
                    final isSelected = _selectedColorCode == code;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorCode = code),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 45, height: 45,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: isSelected ? Border.all(width: 3) : null),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    );
                  },
                ),
              ),
              
              const Divider(height: 40),

              // --- YENİ BÖLÜM: DERS SAATLERİ LİSTESİ ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Ders Saatleri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _showAddScheduleDialog,
                    icon: const Icon(Icons.add_alarm),
                    label: const Text("Saat Ekle"),
                  ),
                ],
              ),
              
              // Eklenen Saatleri Gösteren Liste
              if (_addedSchedules.isEmpty)
                Container(
                  padding: const EdgeInsets.all(15),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                  child: const Text("Henüz saat eklenmedi.\nÖrn: Pazartesi 09:00", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                )
              else
                ..._addedSchedules.map((schedule) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.access_time, color: AppColors.primary),
                      title: Text(schedule['dayName']),
                      subtitle: Text("${schedule['start']} - ${schedule['end']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _addedSchedules.remove(schedule);
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),

              const SizedBox(height: 30),

              // --- KAYDET BUTONU ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveCourse,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text("Kaydet ve Bitir", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}