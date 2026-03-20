import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../core/models/question.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  final String topic;

  const QuizScreen({super.key, required this.topic});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().startQuiz(widget.topic);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131F24),
      body: Consumer<QuizProvider>(
        builder: (context, provider, _) {
          switch (provider.state) {
            case QuizState.loading:
              return _LoadingView(topic: widget.topic);
            case QuizState.error:
              return _ErrorView(
                message: provider.errorMessage ?? 'Unknown error',
                onRetry: () => provider.startQuiz(widget.topic),
              );
            case QuizState.ready:
              return _LearnView(
                topic: provider.session!.topic,
                keyFacts: provider.session!.keyFacts,
                questionCount: provider.session!.totalQuestions,
                onStart: provider.beginAnswering,
              );
            case QuizState.answering:
              if (provider.session == null) return const SizedBox();
              final session = provider.session!;
              if (session.isComplete) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultsScreen(session: session),
                      ),
                    );
                  }
                });
                return const SizedBox();
              }
              return _QuizView(
                provider: provider,
                session: session,
              );
            case QuizState.complete:
              final session = provider.session!;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResultsScreen(session: session),
                    ),
                  );
                }
              });
              return const SizedBox();
            case QuizState.idle:
              return const SizedBox();
          }
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final String topic;
  const _LoadingView({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF58CC02)),
          const SizedBox(height: 24),
          Text(
            'Preparing quiz on',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            topic,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Fetching Wikipedia article\nand generating questions...',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF4B4B), size: 56),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58CC02),
              ),
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Go Back',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearnView extends StatelessWidget {
  final String topic;
  final List<String> keyFacts;
  final int questionCount;
  final VoidCallback onStart;

  const _LearnView({
    required this.topic,
    required this.keyFacts,
    required this.questionCount,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1CB0F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1CB0F6).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.quiz, size: 14, color: Color(0xFF1CB0F6)),
                      const SizedBox(width: 5),
                      Text(
                        '$questionCount questions ahead',
                        style: const TextStyle(color: Color(0xFF1CB0F6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Column(
              children: [
                const Icon(Icons.menu_book_rounded, color: Color(0xFF58CC02), size: 40),
                const SizedBox(height: 12),
                const Text(
                  'Learn first, then quiz',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  topic,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Scrollable facts
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              itemCount: keyFacts.length,
              itemBuilder: (context, i) => _FactCard(
                number: i + 1,
                fact: keyFacts[i],
              ),
            ),
          ),

          // Start button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF58CC02),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "I'm ready — Start Quiz",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  final int number;
  final String fact;

  const _FactCard({required this.number, required this.fact});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2F38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D4A5A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF58CC02),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fact,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131F24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

class _QuizView extends StatelessWidget {
  final QuizProvider provider;
  final dynamic session;

  const _QuizView({required this.provider, required this.session});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _QuizHeader(session: session, onQuit: () => Navigator.pop(context)),
          Expanded(
            child: provider.showingFeedback
                ? _FeedbackView(
                    isCorrect: provider.lastAnswerCorrect!,
                    explanation: session.currentQuestion == null
                        ? ''
                        : session.questions[session.currentIndex - 1]
                            .explanation,
                    onNext: provider.nextQuestion,
                  )
                : _QuestionView(
                    question: session.currentQuestion!,
                    onAnswer: provider.submitAnswer,
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuizHeader extends StatelessWidget {
  final dynamic session;
  final VoidCallback onQuit;

  const _QuizHeader({required this.session, required this.onQuit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onQuit,
            child: const Icon(Icons.close, color: Colors.white54, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: session.totalQuestions == 0
                    ? 0
                    : session.currentIndex / session.totalQuestions,
                minHeight: 10,
                backgroundColor: const Color(0xFF1E2F38),
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFF58CC02)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  i < session.lives ? Icons.favorite : Icons.favorite_border,
                  color: i < session.lives
                      ? const Color(0xFFFF4B4B)
                      : Colors.white24,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final Question question;
  final Function(dynamic) onAnswer;

  const _QuestionView({required this.question, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionTypeLabel(type: question.type),
          const SizedBox(height: 16),
          Text(
            question.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          _QuestionAnswerWidget(question: question, onAnswer: onAnswer),
        ],
      ),
    );
  }
}

class _QuestionTypeLabel extends StatelessWidget {
  final QuestionType type;
  const _QuestionTypeLabel({required this.type});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    IconData icon;

    switch (type) {
      case QuestionType.multipleChoice:
        label = 'Multiple Choice';
        color = const Color(0xFF1CB0F6);
        icon = Icons.radio_button_checked;
        break;
      case QuestionType.trueFalse:
        label = 'True or False';
        color = const Color(0xFF9B59B6);
        icon = Icons.check_circle_outline;
        break;
      case QuestionType.fillBlank:
        label = 'Fill in the Blank';
        color = const Color(0xFFFF9F00);
        icon = Icons.edit_note;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuestionAnswerWidget extends StatefulWidget {
  final Question question;
  final Function(dynamic) onAnswer;

  const _QuestionAnswerWidget(
      {required this.question, required this.onAnswer});

  @override
  State<_QuestionAnswerWidget> createState() => _QuestionAnswerWidgetState();
}

class _QuestionAnswerWidgetState extends State<_QuestionAnswerWidget> {
  final _fillController = TextEditingController();

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.question.type) {
      case QuestionType.multipleChoice:
        return _MultipleChoiceWidget(
          options: widget.question.options!,
          onAnswer: widget.onAnswer,
        );
      case QuestionType.trueFalse:
        return _TrueFalseWidget(onAnswer: widget.onAnswer);
      case QuestionType.fillBlank:
        return _FillBlankWidget(
          controller: _fillController,
          onAnswer: widget.onAnswer,
        );
    }
  }
}

class _MultipleChoiceWidget extends StatelessWidget {
  final List<String> options;
  final Function(dynamic) onAnswer;

  const _MultipleChoiceWidget(
      {required this.options, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        options.length,
        (i) => GestureDetector(
          onTap: () => onAnswer(i),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2F38),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2D4A5A)),
            ),
            child: Text(
              options[i],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrueFalseWidget extends StatelessWidget {
  final Function(dynamic) onAnswer;

  const _TrueFalseWidget({required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TrueFalseButton(
            label: 'True',
            icon: Icons.check_circle,
            color: const Color(0xFF58CC02),
            onTap: () => onAnswer(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TrueFalseButton(
            label: 'False',
            icon: Icons.cancel,
            color: const Color(0xFFFF4B4B),
            onTap: () => onAnswer(false),
          ),
        ),
      ],
    );
  }
}

class _TrueFalseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TrueFalseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FillBlankWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(dynamic) onAnswer;

  const _FillBlankWidget(
      {required this.controller, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF1E2F38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
          onSubmitted: (_) {
            if (controller.text.isNotEmpty) onAnswer(controller.text);
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) onAnswer(controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackView extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  final VoidCallback onNext;

  const _FeedbackView({
    required this.isCorrect,
    required this.explanation,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? const Color(0xFF58CC02) : const Color(0xFFFF4B4B);
    final label = isCorrect ? 'Correct!' : 'Incorrect';
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.3), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              explanation,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
