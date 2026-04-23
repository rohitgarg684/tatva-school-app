class HomeworkModel {
  final String id;
  final String title;
  final String subject;
  final String className;
  final String dueDate;
  final bool isCompleted;

  const HomeworkModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.className,
    required this.dueDate,
    this.isCompleted = false,
  });

  HomeworkModel copyWith({bool? isCompleted}) {
    return HomeworkModel(
      id: id,
      title: title,
      subject: subject,
      className: className,
      dueDate: dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory HomeworkModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return HomeworkModel(
      id: id ?? data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      className: data['className'] as String? ?? '',
      dueDate: data['dueDate'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'className': className,
      'dueDate': dueDate,
      'isCompleted': isCompleted,
    };
  }
}
