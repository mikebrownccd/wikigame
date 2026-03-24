import 'dart:math';
import '../models/question.dart';

class QuestionGenerator {
  final _random = Random();

  static const _skipWords = {
    'The', 'A', 'An', 'In', 'On', 'At', 'By', 'For', 'With', 'From',
    'To', 'Of', 'And', 'But', 'Or', 'As', 'Is', 'Was', 'Are', 'Were',
    'It', 'Its', 'He', 'She', 'They', 'His', 'Her', 'Their', 'This',
    'That', 'These', 'Those', 'Which', 'Who', 'When', 'Where', 'How',
    'What', 'After', 'Before', 'During', 'While', 'Since', 'Until',
    'Although', 'However', 'Therefore', 'Also', 'Then', 'Such', 'Other',
    'First', 'Second', 'Third', 'One', 'Two', 'Three', 'Many', 'Most',
    'Some', 'Several', 'New', 'Old', 'Both', 'Each', 'Later', 'Early',
  };

  static final _yearRegex = RegExp(r'\b(1[0-9]{3}|20[0-9]{2})\b');

  List<String> extractKeyFacts(String content) {
    final sentences = _extractSentences(content);
    if (sentences.isEmpty) return [];

    // Prefer sentences with dates/numbers (most factual), then proper nouns
    final withDates = sentences
        .where((s) => _yearRegex.hasMatch(s))
        .take(3)
        .toList();
    final withNouns = sentences
        .where((s) => !withDates.contains(s) && _properNounsIn(s).length >= 2)
        .take(3)
        .toList();
    final others = sentences
        .where((s) => !withDates.contains(s) && !withNouns.contains(s))
        .take(3)
        .toList();

    final facts = [...withDates, ...withNouns, ...others].take(3).toList();
    // Return in original article order
    return sentences.where((s) => facts.contains(s)).take(3).toList();
  }

  List<Question> generateQuestions(String topic, String content) {
    final sentences = _extractSentences(content);
    if (sentences.isEmpty) return [];

    final allNouns = _collectProperNouns(sentences);
    final questions = <Question>[];
    final used = <int>{};

    // 2 multiple choice (fill-blank style with options)
    _tryAdd(questions, _makeMultipleChoice(sentences, allNouns, used));
    _tryAdd(questions, _makeMultipleChoice(sentences, allNouns, used));

    // 2 true/false
    _tryAdd(questions, _makeTrueFalse(sentences, allNouns, used, wantTrue: true));
    _tryAdd(questions, _makeTrueFalse(sentences, allNouns, used, wantTrue: false));

    // 1 fill-in-the-blank
    _tryAdd(questions, _makeFillBlank(sentences, used));

    // Pad if needed with simple true statements
    for (int i = 0; i < sentences.length && questions.length < 5; i++) {
      if (used.contains(i)) continue;
      questions.add(Question(
        type: QuestionType.trueFalse,
        question: '${sentences[i]}.',
        isTrue: true,
        explanation: 'This statement comes directly from the article.',
      ));
      used.add(i);
    }

    questions.shuffle(_random);
    return questions.take(5).toList();
  }

  void _tryAdd(List<Question> list, Question? q) {
    if (q != null) list.add(q);
  }

  List<String> _extractSentences(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Split at sentence boundaries: period/! followed by space and capital letter
    final parts = normalized.split(RegExp(r'(?<=[.!])\s+(?=[A-Z])'));
    return parts
        .map((s) => s.trim().replaceAll(RegExp(r'[.!]+$'), ''))
        .where((s) => s.length >= 50 && s.length <= 220)
        .where((s) => s.contains(' '))
        .where((s) => !s.startsWith('==')) // skip wiki headings
        .toList();
  }

  List<String> _collectProperNouns(List<String> sentences) {
    final nouns = <String>{};
    for (final s in sentences) {
      nouns.addAll(_properNounsIn(s));
    }
    return nouns.toList();
  }

  // Returns capitalized words that appear mid-sentence (not the first word)
  List<String> _properNounsIn(String sentence) {
    final words = sentence.split(RegExp(r'\s+'));
    final nouns = <String>[];
    for (int i = 1; i < words.length; i++) {
      final clean = words[i].replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (clean.length > 2 &&
          clean[0] == clean[0].toUpperCase() &&
          clean[0] != clean[0].toLowerCase() &&
          !_skipWords.contains(clean)) {
        nouns.add(clean);
      }
    }
    return nouns;
  }

  // Multiple choice: blank out a proper noun or year and offer 4 options
  Question? _makeMultipleChoice(
    List<String> sentences,
    List<String> allNouns,
    Set<int> used,
  ) {
    // Prefer sentences with a year
    for (int i = 0; i < sentences.length; i++) {
      if (used.contains(i)) continue;
      final s = sentences[i];
      final m = _yearRegex.firstMatch(s);
      if (m == null) continue;

      final correct = m.group(0)!;
      final year = int.parse(correct);
      final distractors = {
        '${year - 20}',
        '${year + 15}',
        '${year - 5}',
        '${year + 30}',
      }.where((d) => d != correct).take(3).toList();
      if (distractors.length < 3) continue;

      final options = [correct, ...distractors]..shuffle(_random);
      used.add(i);
      return Question(
        type: QuestionType.multipleChoice,
        question: '${s.replaceFirst(correct, '___')}.',
        options: options,
        correctIndex: options.indexOf(correct),
        explanation: 'The correct answer is $correct. ($s.)',
      );
    }

    // Fall back: blank out a proper noun
    for (int i = 0; i < sentences.length; i++) {
      if (used.contains(i)) continue;
      final s = sentences[i];
      final nouns = _properNounsIn(s);
      if (nouns.isEmpty) continue;

      final correct = nouns.first;
      final distractors = allNouns
          .where((n) => n != correct)
          .toSet()
          .toList()
        ..shuffle(_random);
      if (distractors.length < 3) continue;

      final options = [correct, ...distractors.take(3)]..shuffle(_random);
      used.add(i);
      return Question(
        type: QuestionType.multipleChoice,
        question: '${s.replaceFirst(correct, '___')}.',
        options: options,
        correctIndex: options.indexOf(correct),
        explanation: 'The correct answer is $correct. ($s.)',
      );
    }

    return null;
  }

  // True/false: real sentence (true) or sentence with swapped year/noun (false)
  Question? _makeTrueFalse(
    List<String> sentences,
    List<String> allNouns,
    Set<int> used, {
    required bool wantTrue,
  }) {
    for (int i = 0; i < sentences.length; i++) {
      if (used.contains(i)) continue;
      final s = sentences[i];

      if (wantTrue) {
        used.add(i);
        return Question(
          type: QuestionType.trueFalse,
          question: '$s.',
          isTrue: true,
          explanation: 'True. This statement appears directly in the article.',
        );
      }

      // Try to falsify via year swap
      final m = _yearRegex.firstMatch(s);
      if (m != null) {
        final year = int.parse(m.group(0)!);
        final fake = year + (_random.nextBool() ? 25 : -25);
        used.add(i);
        return Question(
          type: QuestionType.trueFalse,
          question: '${s.replaceFirst(m.group(0)!, '$fake')}.',
          isTrue: false,
          explanation:
              'False. The correct year is $year, not $fake. ($s.)',
        );
      }

      // Try to falsify via noun swap
      final nouns = _properNounsIn(s);
      final others =
          allNouns.where((n) => !nouns.contains(n)).toList()..shuffle(_random);
      if (nouns.isNotEmpty && others.isNotEmpty) {
        final target = nouns[_random.nextInt(nouns.length)];
        final replacement = others.first;
        if (s.contains(target)) {
          used.add(i);
          return Question(
            type: QuestionType.trueFalse,
            question: '${s.replaceFirst(target, replacement)}.',
            isTrue: false,
            explanation:
                'False. "$replacement" is incorrect here; the article says "$target". ($s.)',
          );
        }
      }
    }

    return null;
  }

  // Fill-in-the-blank: remove a year or proper noun
  Question? _makeFillBlank(List<String> sentences, Set<int> used) {
    // Prefer years
    for (int i = 0; i < sentences.length; i++) {
      if (used.contains(i)) continue;
      final s = sentences[i];
      final m = _yearRegex.firstMatch(s);
      if (m != null) {
        used.add(i);
        return Question(
          type: QuestionType.fillBlank,
          question: '${s.replaceFirst(m.group(0)!, '___')}.',
          answer: m.group(0)!,
          explanation: 'The answer is ${m.group(0)!}. ($s.)',
        );
      }
    }

    // Fall back to proper noun
    for (int i = 0; i < sentences.length; i++) {
      if (used.contains(i)) continue;
      final s = sentences[i];
      final nouns = _properNounsIn(s);
      if (nouns.isEmpty) continue;
      final target = nouns.first;
      if (!s.contains(target)) continue;
      used.add(i);
      return Question(
        type: QuestionType.fillBlank,
        question: '${s.replaceFirst(target, '___')}.',
        answer: target,
        explanation: 'The answer is $target. ($s.)',
      );
    }

    return null;
  }
}
