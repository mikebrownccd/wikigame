enum QuestionType { multipleChoice, trueFalse, fillBlank }

class Question {
  final QuestionType type;
  final String question;
  final String explanation;

  // Multiple choice
  final List<String>? options;
  final int? correctIndex;

  // True/false
  final bool? isTrue;

  // Fill in the blank
  final String? answer;

  const Question({
    required this.type,
    required this.question,
    required this.explanation,
    this.options,
    this.correctIndex,
    this.isTrue,
    this.answer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    QuestionType type;
    switch (typeStr) {
      case 'multiple_choice':
        type = QuestionType.multipleChoice;
        break;
      case 'true_false':
        type = QuestionType.trueFalse;
        break;
      case 'fill_blank':
        type = QuestionType.fillBlank;
        break;
      default:
        type = QuestionType.multipleChoice;
    }

    return Question(
      type: type,
      question: json['question'] as String,
      explanation: json['explanation'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
      correctIndex: json['correct_index'] as int?,
      isTrue: json['is_true'] as bool?,
      answer: json['answer'] as String?,
    );
  }

  bool checkAnswer(dynamic userAnswer) {
    switch (type) {
      case QuestionType.multipleChoice:
        return userAnswer == correctIndex;
      case QuestionType.trueFalse:
        return userAnswer == isTrue;
      case QuestionType.fillBlank:
        final userStr = (userAnswer as String).trim().toLowerCase();
        final correctStr = answer!.trim().toLowerCase();
        return userStr == correctStr ||
            correctStr.contains(userStr) ||
            userStr.contains(correctStr);
    }
  }
}
