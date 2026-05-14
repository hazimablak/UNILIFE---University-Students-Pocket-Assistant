import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unilife/core/constants/app_colors.dart';

class StudyTimerScreen extends StatefulWidget {
  const StudyTimerScreen({super.key});

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen> {
  // Varsayılan ve Seçilen Dakika
  double _selectedMinutes = 25; 
  int _secondsRemaining = 25 * 60;
  
  Timer? _timer;
  bool _isRunning = false;
  
  // Arka planda biriken "Bu oturumdaki" çalışma süresi (Saniye)
  int _sessionSeconds = 0; 

  @override
  void initState() {
    super.initState();
    _secondsRemaining = (_selectedMinutes * 60).toInt();
  }

  // --- SAYAÇ BAŞLAT ---
  void _startTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() => _isRunning = true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _sessionSeconds++; // Her saniye burası artıyor
        } else {
          _finishSession(); // Süre tamamen bitti
        }
      });
    });
  }

  // --- SAYAÇ DURAKLAT ---
  void _stopTimer() {
    if (_timer != null) _timer!.cancel();
    setState(() => _isRunning = false);
  }

  // --- KAYDET VE BİTİR ---
  Future<void> _finishSession() async {
    _stopTimer();

    // Saniyeyi dakikaya çevir (Aşağı yuvarla)
    int minutesStudied = (_sessionSeconds / 60).floor();

    if (minutesStudied >= 1) { // DÜZELTME: En az 1 dakika varsa kaydet
      final prefs = await SharedPreferences.getInstance();
      int currentTotal = prefs.getInt('todayStudyTime') ?? 0;
      
      // Eski toplama yeniyi ekle
      await prefs.setInt('todayStudyTime', currentTotal + minutesStudied);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harika! $minutesStudied dakika hanene yazıldı. 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // 1 dakikadan azsa uyarı ver
      if (mounted && _sessionSeconds > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('1 dakikadan kısa çalışmalar kaydedilmez.'),
             backgroundColor: Colors.orange,
             duration: Duration(seconds: 2),
           ),
        );
      }
    }
    
    // Her şeyi sıfırla
    setState(() {
      _secondsRemaining = (_selectedMinutes * 60).toInt();
      _sessionSeconds = 0;
      _isRunning = false;
    });
  }

  // Slider değişince süreyi güncelle
  void _updateDuration(double value) {
    setState(() {
      _selectedMinutes = value;
      _secondsRemaining = (value * 60).toInt();
    });
  }

  // Sayfadan çıkarken kontrol et
  @override
  void dispose() {
    if (_timer != null) _timer!.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int min = seconds ~/ 60;
    int sec = seconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    double progress = _secondsRemaining / (_selectedMinutes * 60);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Odaklanma Modu 🎯"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             // DÜZELTME: Çıkarken eğer 60 saniye dolduysa kaydet
             if (_sessionSeconds >= 60) {
               _finishSession(); 
             }
             Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // DAİRESEL SAYAÇ
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250, height: 250,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 20,
                  backgroundColor: Colors.grey[200],
                  color: _isRunning ? AppColors.accent : AppColors.primary,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(_secondsRemaining),
                    style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (_isRunning)
                    Text(
                      "Kazanılan: ${(_sessionSeconds / 60).floor()} dk", 
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    )
                  else
                    const Text("Süreyi Ayarla", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 30),

          // SÜRE AYARLAMA SLIDER (Sadece dururken görünür)
          if (!_isRunning) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text("Hedef Süre: ${_selectedMinutes.toInt()} dakika", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Slider(
                    value: _selectedMinutes,
                    min: 5,
                    max: 120,
                    divisions: 23,
                    activeColor: AppColors.primary,
                    label: "${_selectedMinutes.toInt()} dk",
                    onChanged: _updateDuration,
                  ),
                ],
              ),
            ),
          ] else ...[
             const SizedBox(height: 50),
          ],
          
          const SizedBox(height: 20),
          
          // BUTONLAR
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRunning)
                ElevatedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("BAŞLAT"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                )
              else
                ElevatedButton.icon(
                  onPressed: _stopTimer,
                  icon: const Icon(Icons.pause),
                  label: const Text("DURAKLAT"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                ),
              
              const SizedBox(width: 20),
              
              // BİTİR VE KAYDET BUTONU
              IconButton(
                onPressed: () {
                  // Manuel bitirme
                  if (_sessionSeconds > 0) {
                    _finishSession();
                  } else {
                    setState(() {
                      _secondsRemaining = (_selectedMinutes * 60).toInt();
                      _isRunning = false;
                    });
                  }
                },
                icon: const Icon(Icons.stop_circle_outlined, size: 40),
                color: Colors.red,
                tooltip: "Bitir ve Kaydet",
              )
            ],
          )
        ],
      ),
    );
  }
}