import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:unilife/core/constants/app_colors.dart';
import 'package:unilife/core/database/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- PROFİL VERİLERİ ---
  String _userName = "Öğrenci";
  String? _profileImagePath;
  int _totalStudyMinutes = 0; // Toplam çalışma süresi

  // --- BÜTÇE VERİLERİ ---
  double _totalBalance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<Map<String, dynamic>> _transactions = [];

  // --- AYARLAR ---
  bool _notificationHomework = true;
  bool _notificationExam = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBudget();
  }

  // --- 1. KULLANICI & İSTATİSTİK YÜKLEME ---
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "Öğrenci";
      _profileImagePath = prefs.getString('profileImage');
      _totalStudyMinutes = prefs.getInt('todayStudyTime') ?? 0;
    });
  }

  // --- 2. BÜTÇE YÜKLEME ---
  Future<void> _loadBudget() async {
    final db = DatabaseHelper();
    
    // Son 5 işlemi çekiyoruz
    final data = await db.rawQuery('SELECT * FROM transactions ORDER BY date DESC LIMIT 5'); 
    
    // Bakiyeyi Hesapla
    final allData = await db.queryAllRows('transactions'); 
    
    double inc = 0;
    double exp = 0;
    for (var item in allData) {
      if (item['is_expense'] == 1) {
        exp += item['amount'] as double;
      } else {
        inc += item['amount'] as double;
      }
    }

    setState(() {
      _transactions = data;
      _totalIncome = inc;
      _totalExpense = exp;
      _totalBalance = inc - exp;
    });
  }

  // --- İŞLEM EKLEME (GELİR/GİDER) ---
  void _addTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = true; // Varsayılan Gider

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("İşlem Ekle"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gelir / Gider Seçimi
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text("Gider (-)", style: TextStyle(color: Colors.white)),
                        selected: isExpense,
                        selectedColor: Colors.redAccent,
                        onSelected: (val) => setDialogState(() => isExpense = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text("Gelir (+)", style: TextStyle(color: Colors.white)),
                        selected: !isExpense,
                        selectedColor: Colors.green,
                        onSelected: (val) => setDialogState(() => isExpense = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(hintText: "Açıklama (Örn: Kahve)"),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: "Tutar (TL)"),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    final db = DatabaseHelper();
                    await db.insert('transactions', {
                      'title': titleController.text,
                      'amount': double.parse(amountController.text),
                      'is_expense': isExpense ? 1 : 0,
                      'date': DateTime.now().toIso8601String(),
                    });
                    _loadBudget(); // Ekranı yenile
                    Navigator.pop(context);
                  }
                },
                child: const Text("Ekle"),
              )
            ],
          );
        },
      ),
    );
  }

  // --- PROFİL FOTOĞRAFI GÜNCELLEME ---
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
    return Scaffold(
      appBar: AppBar(title: const Text("Profilim"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- 1. PROFİL KARTI ---
            _buildProfileHeader(),
            
            const SizedBox(height: 30),

            // --- 2. HAFTALIK İSTATİSTİK ---
            _buildStatisticsCard(),

            const SizedBox(height: 30),

            // --- 3. BÜTÇE LITE ---
            _buildBudgetCard(),

            const SizedBox(height: 30),
            
            // --- YENİ: GEÇMİŞ İŞLEMLER LİSTESİ ---
            _buildTransactionHistory(),
            
            const SizedBox(height: 30),
            
            // --- 4. AYARLAR ---
            _buildSettingsList(),
          ],
        ),
      ),
    );
  }

  // WIDGET: Son İşlemler Listesi
  Widget _buildTransactionHistory() {
    if (_transactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Son Harcamalar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        
        ..._transactions.map((tx) {
          final isExpense = tx['is_expense'] == 1;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isExpense ? Colors.red : Colors.green).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isExpense ? Colors.red : Colors.green,
                  size: 20,
                ),
              ),
              title: Text(tx['title'] ?? "İşlem"),
              trailing: Text(
                "${isExpense ? '-' : '+'}${tx['amount']} ₺",
                style: TextStyle(
                  color: isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // WIDGET: Profil Başlığı
  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                  image: _profileImagePath != null
                      ? DecorationImage(image: FileImage(File(_profileImagePath!)), fit: BoxFit.cover)
                      : const DecorationImage(image: NetworkImage("https://i.pravatar.cc/150?img=12"), fit: BoxFit.cover),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(_userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text("Bilgisayar Mühendisliği • 3. Sınıf", style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  // WIDGET: İstatistik Kartı
  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Çalışma Analizi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text("Toplam: $_totalStudyMinutes dk", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar("Pzt", 40),
              _buildBar("Sal", 70),
              _buildBar("Çar", 30),
              _buildBar("Per", 90),
              _buildBar("Cum", 50),
              _buildBar("Cmt", 20),
              _buildBar("Paz", 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double heightPct) {
    return Column(
      children: [
        Container(
          width: 8,
          height: heightPct, 
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  // WIDGET: Bütçe Kartı
  Widget _buildBudgetCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Cüzdanım (Lite)", style: TextStyle(color: Colors.white, fontSize: 16)),
              IconButton(
                onPressed: _addTransactionDialog, 
                icon: const Icon(Icons.add_circle, color: Colors.white),
                tooltip: "İşlem Ekle",
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${_totalBalance.toStringAsFixed(2)} ₺", 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBudgetInfo("Gelir", "+$_totalIncome ₺", Colors.greenAccent),
              Container(width: 1, height: 30, color: Colors.white30),
              _buildBudgetInfo("Gider", "-$_totalExpense ₺", Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  // WIDGET: Ayarlar Listesi
  Widget _buildSettingsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ayarlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SwitchListTile(
          title: const Text("Ödev Hatırlatıcı"),
          subtitle: const Text("Son gün yaklaşınca bildir"),
          value: _notificationHomework,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _notificationHomework = val),
        ),
        SwitchListTile(
          title: const Text("Sınav Alarmları"),
          subtitle: const Text("Sınav sabahı uyandır"),
          value: _notificationExam,
          activeColor: AppColors.primary,
          onChanged: (val) => setState(() => _notificationExam = val),
        ),
        ListTile(
          leading: const Icon(Icons.star, color: Colors.orange),
          title: const Text("Pro Sürüm (Kilitli)"),
          subtitle: const Text("Reklamsız ve ekstra temalar"),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yakında gelecek! 🚀')));
          },
        ),
      ],
    );
  }
}