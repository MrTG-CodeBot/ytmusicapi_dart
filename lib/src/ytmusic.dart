import 'ytmusic_base.dart';
import 'navigation.dart';
import 'mixins/search_mixin.dart';
import 'mixins/playlists_mixin.dart';
import 'mixins/music_mixin.dart';
import 'mixins/lyrics_mixin.dart';

class YTMusic extends YTMusicBase with PlaylistsMixin, SearchMixin, LyricsMixin {
  YTMusic({
    super.auth,
    super.user,
    super.client,
    super.proxies,
    super.language,
    super.location,
  }) : super();



  Future<List<dynamic>> getSearchSuggestions(String query, {bool detailedRuns = false}) async {
    final response = await sendRequest('music/get_search_suggestions', {'input': query});
    final contents = (response['contents'] as List?) ?? const [];
    if (contents.isEmpty) return const [];
    final section = (contents.first as Map)['searchSuggestionsSectionRenderer'] as Map?;
    final raw = section?['contents'] as List?;
    if (raw == null || raw.isEmpty) return const [];
    final List<dynamic> suggestions = [];
    for (final item in raw.cast<Map>()) {
      Map<String, dynamic>? suggestionContent;
      String? feedbackToken;
      if (item.containsKey('historySuggestionRenderer')) {
        suggestionContent = item['historySuggestionRenderer'] as Map<String, dynamic>;
        feedbackToken = nav<String>(suggestionContent,
            ['serviceEndpoint', 'feedbackEndpoint', 'feedbackToken'],
            noneIfAbsent: true);
      } else {
        suggestionContent = item['searchSuggestionRenderer'] as Map<String, dynamic>;
      }
      final text = nav<String>(suggestionContent,
          ['navigationEndpoint', 'searchEndpoint', 'query']);
      final runs = (suggestionContent['suggestion'] as Map?)?['runs'];
      if (detailedRuns) {
        suggestions.add({
          'text': text,
          'runs': runs,
          'fromHistory': feedbackToken != null,
          'feedbackToken': feedbackToken,
        });
      } else {
        suggestions.add(text);
      }
    }
    return suggestions;
  }
}


