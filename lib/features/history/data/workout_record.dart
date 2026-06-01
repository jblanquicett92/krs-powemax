class WorkoutRecord {
  final String id;
  final String exerciseName;
  final double weight;
  final int reps;
  final double oneRepMax;
  final DateTime date;
  final String unit; // 'kg', 'lbs'
  final String formula; // 'epley', 'brzycki'

  WorkoutRecord({
    required this.id,
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.oneRepMax,
    required this.date,
    required this.unit,
    required this.formula,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseName': exerciseName,
      'weight': weight,
      'reps': reps,
      'oneRepMax': oneRepMax,
      'date': date.toIso8601String(),
      'unit': unit,
      'formula': formula,
    };
  }

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
    return WorkoutRecord(
      id: json['id'] as String,
      exerciseName: json['exerciseName'] as String,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      oneRepMax: (json['oneRepMax'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      unit: json['unit'] as String,
      formula: json['formula'] as String,
    );
  }
}
