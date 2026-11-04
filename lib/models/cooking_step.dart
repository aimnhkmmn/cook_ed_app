class CookingStep {
  final int stepNumber;
  final String instruction;
  bool isCompleted;

  CookingStep({
    required this.stepNumber,
    required this.instruction,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'step_number': stepNumber,
      'instruction': instruction,
      'is_completed': isCompleted,
    };
  }

  factory CookingStep.fromMap(Map<String, dynamic> map) {
    return CookingStep(
      stepNumber: (map['step_number'] is int) ? map['step_number'] : int.tryParse(map['step_number'].toString()) ?? 1,
      instruction: map['instruction']?.toString() ?? '',
      isCompleted: map['is_completed'] == true,
    );
  }
}
