class RoutineExercise {
  final String name;
  final int sets;
  final int reps;
  final String dayGroup; // E.g., 'Día A', 'Día B', etc.
  final bool isBodyweight;

  RoutineExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.dayGroup = 'Día A',
    this.isBodyweight = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'dayGroup': dayGroup,
      'isBodyweight': isBodyweight,
    };
  }

  factory RoutineExercise.fromJson(Map<String, dynamic> json) {
    return RoutineExercise(
      name: json['name'] as String,
      sets: json['sets'] as int? ?? 4,
      reps: json['reps'] as int? ?? 10,
      dayGroup: json['dayGroup'] as String? ?? 'Día A',
      isBodyweight: json['isBodyweight'] as bool? ?? false,
    );
  }

  RoutineExercise copyWith({
    String? name,
    int? sets,
    int? reps,
    String? dayGroup,
    bool? isBodyweight,
  }) {
    return RoutineExercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      dayGroup: dayGroup ?? this.dayGroup,
      isBodyweight: isBodyweight ?? this.isBodyweight,
    );
  }
}

class Routine {
  final String id;
  final String name;
  final List<RoutineExercise> exercises;
  final DateTime dateCreated;
  final bool isDefault;

  Routine({
    required this.id,
    required this.name,
    required this.exercises,
    required this.dateCreated,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'dateCreated': dateCreated.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    var exercisesJson = json['exercises'] as List? ?? [];
    List<RoutineExercise> parsedExercises;
    if (json.containsKey('exerciseNames')) {
      var oldNames = List<String>.from(json['exerciseNames'] as List? ?? []);
      parsedExercises = oldNames.map((name) => RoutineExercise(name: name, sets: 4, reps: 10, dayGroup: 'Día A')).toList();
    } else {
      parsedExercises = exercisesJson
          .map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Routine(
      id: json['id'] as String,
      name: json['name'] as String,
      exercises: parsedExercises,
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Routine copyWith({
    String? id,
    String? name,
    List<RoutineExercise>? exercises,
    DateTime? dateCreated,
    bool? isDefault,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      dateCreated: dateCreated ?? this.dateCreated,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
