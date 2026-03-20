import 'dart:convert';
import 'package:http/http.dart' as http;

class WikipediaArticle {
  final String title;
  final String summary;
  final String? imageUrl;

  const WikipediaArticle({
    required this.title,
    required this.summary,
    this.imageUrl,
  });
}

class WikipediaSearchResult {
  final String title;
  final String description;

  const WikipediaSearchResult({
    required this.title,
    required this.description,
  });
}

class WikipediaService {
  static const _baseUrl = 'https://en.wikipedia.org';

  Future<List<WikipediaSearchResult>> search(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(query)}&format=json&srlimit=10&origin=*',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Wikipedia search failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final searchResults =
        (data['query']['search'] as List<dynamic>).cast<Map<String, dynamic>>();

    return searchResults.map((r) {
      // Strip HTML tags from snippet
      final snippet = (r['snippet'] as String)
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&quot;', '"')
          .replaceAll('&amp;', '&')
          .replaceAll('&#039;', "'");
      return WikipediaSearchResult(
        title: r['title'] as String,
        description: snippet,
      );
    }).toList();
  }

  Future<WikipediaArticle> getArticle(String title) async {
    final uri = Uri.parse(
      '$_baseUrl/api/rest_v1/page/summary/${Uri.encodeComponent(title)}',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Wikipedia article fetch failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return WikipediaArticle(
      title: data['title'] as String,
      summary: data['extract'] as String,
      imageUrl: data['thumbnail']?['source'] as String?,
    );
  }

  Future<String> getFullContent(String title) async {
    final uri = Uri.parse(
      '$_baseUrl/w/api.php?action=query&titles=${Uri.encodeComponent(title)}&prop=extracts&explaintext=true&exsectionformat=plain&format=json&origin=*',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Wikipedia content fetch failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final pages =
        (data['query']['pages'] as Map<String, dynamic>).values.first
            as Map<String, dynamic>;
    final extract = pages['extract'] as String? ?? '';

    // Limit to first 3000 chars to keep Claude prompt reasonable
    return extract.length > 3000 ? extract.substring(0, 3000) : extract;
  }
}
