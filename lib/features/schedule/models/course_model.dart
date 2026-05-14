class Course {
  final int? id;              // Veritabanı otomatik vereceği için başta boş olabilir (?)
  final String name;          // Dersin adı (Matematik)
  final String? instructor;   // Hoca (Dr. Ali - Boş olabilir)
  final String? roomName;     // Sınıf (B-204 - Boş olabilir)
  final String colorCode;     // Renk (#FF5733)
  final double targetGrade;   // Hedef not (AA için 90.0)

  Course({
    this.id,
    required this.name,
    this.instructor,
    this.roomName,
    required this.colorCode,
    this.targetGrade = 0.0,
  });

  // --- FABRİKA AYARLARI (Veritabanından Gelen Veriyi Çevir) ---
  // SQL'den gelen Map'i (JSON gibi düşün), Dart nesnesine çevirir.
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      name: map['name'],
      instructor: map['instructor'],
      roomName: map['room_name'], // SQL'de 'room_name' yazmıştık
      colorCode: map['color_code'],
      targetGrade: map['target_grade'] ?? 0.0,
    );
  }

  // --- PAKETLEME (Veritabanına Gönder) ---
  // Dart nesnesini, SQL'in anlayacağı Map formatına çevirir.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'instructor': instructor,
      'room_name': roomName,
      'color_code': colorCode,
      'target_grade': targetGrade,
    };
  }
}