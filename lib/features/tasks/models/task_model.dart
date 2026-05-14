class Task {
  final int? id;
  final int? courseId;       // Hangi derse ait?
  final String title;        // "Final Projesi"
  final String type;         // "HOMEWORK" veya "EXAM"
  final DateTime dueDate;    // Teslim tarihi
  final bool isCompleted;    // Tamamlandı mı?
  final DateTime? reminderTime; // Hatırlatma

  Task({
    this.id,
    this.courseId,
    required this.title,
    required this.type,
    required this.dueDate,
    this.isCompleted = false,
    this.reminderTime,
  });

  // SQL -> Dart
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      courseId: map['course_id'],
      title: map['title'],
      type: map['type'],
      // SQL tarihleri "milisaniye" (int) olarak tutar, biz DateTime'a çeviriyoruz
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date']),
      isCompleted: map['is_completed'] == 1, // SQL'de 1 ise true, 0 ise false
      reminderTime: map['reminder_time'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['reminder_time']) 
          : null,
    );
  }

  // Dart -> SQL
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'type': type,
      // DateTime'ı milisaniyeye (int) çevirip kaydediyoruz
      'due_date': dueDate.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
      'reminder_time': reminderTime?.millisecondsSinceEpoch,
    };
  }
}