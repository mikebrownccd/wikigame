import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/wikipedia_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/claude_service.dart';
import '../providers/quiz_provider.dart';
import 'quiz_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _wikipedia = WikipediaService();
  List<WikipediaSearchResult> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _searching = true;
      _results = [];
    });
    try {
      final results = await _wikipedia.search(query);
      setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _startQuiz(BuildContext context, String topic) async {
    // Capture context-dependent objects before any async gap
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final storage = StorageService();
    final apiKey = await storage.loadApiKey();

    if (!mounted) return;

    if (apiKey == null || apiKey.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please set your Anthropic API key in Settings first.'),
          backgroundColor: Color(0xFFFF4B4B),
        ),
      );
      return;
    }

    final quizProvider = QuizProvider(
      wikipedia: _wikipedia,
      claude: ClaudeService(apiKey: apiKey),
    );

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: quizProvider,
          child: QuizScreen(topic: topic),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131F24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131F24),
        elevation: 0,
        title: const Text(
          'Choose a Topic',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Search Wikipedia...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E2F38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF58CC02),
                          ),
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_results.isEmpty && !_searching)
            const Expanded(
              child: _SuggestedTopics(),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final result = _results[i];
                  return _TopicTile(
                    title: result.title,
                    description: result.description,
                    onTap: () => _startQuiz(context, result.title),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestedTopics extends StatelessWidget {
  const _SuggestedTopics();

  static const _suggestions = [
    ('Solar System', Icons.rocket_launch, Color(0xFF9B59B6)),
    ('World War II', Icons.history_edu, Color(0xFFE74C3C)),
    ('Leonardo da Vinci', Icons.brush, Color(0xFF1CB0F6)),
    ('Amazon River', Icons.water, Color(0xFF58CC02)),
    ('Artificial Intelligence', Icons.psychology, Color(0xFFFF9F00)),
    ('Ancient Rome', Icons.account_balance, Color(0xFFE67E22)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text(
            'Popular Topics',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: _suggestions.map((s) {
              return _SuggestionCard(
                title: s.$1,
                icon: s.$2,
                color: s.$3,
                onTap: () {
                  final state =
                      context.findAncestorStateOfType<_SearchScreenState>();
                  state?._searchController.text = s.$1;
                  state?._search(s.$1);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 26),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _TopicTile({
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2F38),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white30,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
