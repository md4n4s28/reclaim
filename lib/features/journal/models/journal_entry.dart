class JournalEntry {
  final String id;
  final DateTime date;
  final int mood; // 1-5
  final List<String> triggers;
  final String thoughts;
  final String gratitude;
  final int urgeIntensity; // 1-10

  JournalEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.triggers,
    required this.thoughts,
    required this.gratitude,
    required this.urgeIntensity,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'mood': mood,
        'triggers': triggers,
        'thoughts': thoughts,
        'gratitude': gratitude,
        'urgeIntensity': urgeIntensity,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'],
        date: DateTime.parse(json['date']),
        mood: json['mood'],
        triggers: List<String>.from(json['triggers']),
        thoughts: json['thoughts'],
        gratitude: json['gratitude'],
        urgeIntensity: json['urgeIntensity'],
      );
}
