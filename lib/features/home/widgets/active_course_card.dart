import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unilife/core/constants/app_colors.dart';
import 'package:unilife/core/database/database_helper.dart';

class ActiveCourseCard extends StatefulWidget {
  const ActiveCourseCard({super.key});

  @override
  State<ActiveCourseCard> createState() => _ActiveCourseCardState();
}

class _ActiveCourseCardState extends State<ActiveCourseCard> {
  // Kartın Durum Değişkenleri
  String _title = "Serbest Zaman";
  String _subtitle = "Şu an dersin yok, keyfine bak! ☕";
  String _timeInfo = "";
  Color _cardColor = AppColors.primary; // Varsayılan Mor
  IconData _icon = Icons.nightlife;
  
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkSchedule(); // Açılır açılmaz kontrol et
    // Her 1 dakikada bir durumu güncelle (Ders biterse anında değişsin)
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _checkSchedule());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- ZAMAN MANTIK MOTORU ---
  Future<void> _checkSchedule() async {
    final db = DatabaseHelper();
    final now = DateTime.now();
    final todayIndex = now.weekday; // 1=Pzt, 7=Paz

    // Bugünün derslerini çek
    final classes = await db.rawQuery('''
      SELECT s.start_time, s.end_time, c.name, c.room_name 
      FROM schedules s
      JOIN courses c ON s.course_id = c.id
      WHERE s.day_of_week = ?
      ORDER BY s.start_time ASC
    ''', [todayIndex]);

    bool foundActive = false;

    for (var lesson in classes) {
      // Saatleri String'den DateTime'a çevir (Örn: "09:00" -> Bugün 09:00)
      final startTime = _parseTime(lesson['start_time'] as String, now);
      final endTime = _parseTime(lesson['end_time'] as String, now);

      if (startTime == null || endTime == null) continue;

      // 1. DURUM: ŞU AN DERS VAR MI?
      if (now.isAfter(startTime) && now.isBefore(endTime)) {
        setState(() {
          _title = lesson['name'] as String;
          _subtitle = "📍 ${lesson['room_name'] ?? 'Sınıf Yok'} • Ders İşleniyor";
          _timeInfo = "${lesson['start_time']} - ${lesson['end_time']}";
          _cardColor = Colors.redAccent; // Aktif ders rengi
          _icon = Icons.school;
        });
        foundActive = true;
        break; 
      }

      // 2. DURUM: YAKLAŞAN DERS VAR MI? (60 dk içinde)
      final diff = startTime.difference(now).inMinutes;
      if (diff > 0 && diff <= 60) {
        setState(() {
          _title = lesson['name'] as String;
          _subtitle = "Sonraki Ders • $diff dk kaldı";
          _timeInfo = "${lesson['start_time']} Başlangıç";
          _cardColor = Colors.orange; // Yaklaşan ders rengi
          _icon = Icons.access_time_filled;
        });
        foundActive = true;
        break;
      }
    }

    // 3. DURUM: HİÇBİR ŞEY YOKSA "SERBEST ZAMAN"
    if (!foundActive) {
      setState(() {
        _title = "Serbest Zaman";
        _subtitle = "Şu an dersin yok, keyfine bak! ☕";
        _timeInfo = "";
        _cardColor = AppColors.primary; // Mor
        _icon = Icons.nightlife;
      });
    }
  }

  // "14:30" formatındaki saati bugünün tarihine ekler
  DateTime? _parseTime(String timeStr, DateTime now) {
    try {
      final parts = timeStr.split(':');
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _cardColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sol İkon Kutusu
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 15),
          
          // Yazılar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Sağdaki Saat Bilgisi (Varsa)
          if (_timeInfo.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _timeInfo,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}