import '../exceptions.dart';
import '../search_params.dart';
import '../ytmusic_base.dart';
import '../navigation.dart';
import '../parsers/search.dart' as ps;
import '../continuations.dart' as cont;

mixin SearchMixin on YTMusicBase {
  Future<List<dynamic>> search({
    required String query,
    String? filter,
    String? scope,
    int limit = 20,
    bool ignoreSpelling = false,
  }) async {
    final allowedFilters = <String>{
      'albums',
      'artists',
      'playlists',
      'community_playlists',
      'featured_playlists',
      'songs',
      'videos',
      'profiles',
      'podcasts',
      'episodes',
      'uploads',
    };
    if (filter != null && !allowedFilters.contains(filter)) {
      throw YTMusicUserError(
          'Invalid filter provided. Please use one of the following filters or leave out the parameter: ${allowedFilters.join(', ')}');
    }

    final scopes = <String>{'library', 'uploads'};
    if (scope != null && !scopes.contains(scope)) {
      throw YTMusicUserError(
          'Invalid scope provided. Please use one of the following scopes or leave out the parameter: ${scopes.join(', ')}');
    }
    if (scope == 'uploads' && filter != null) {
      throw YTMusicUserError(
          'No filter can be set when searching uploads. Please unset the filter parameter when scope is set to uploads.');
    }
    if (scope == 'library' && filter != null && (filter == 'community_playlists' || filter == 'featured_playlists')) {
      throw YTMusicUserError(
          '$filter cannot be set when searching library. Please use one of the following filters or leave out the parameter: albums, artists, songs, videos, profiles, podcasts, episodes');
    }

    final body = <String, dynamic>{'query': query};
    final params = getSearchParams(filter, scope, ignoreSpelling);
    if (params != null) body['params'] = params;

    final response = await sendRequest('search', body);
    if (response['contents'] == null) return <dynamic>[];
    dynamic results;
    if (response['contents'] is Map && (response['contents'] as Map).containsKey('tabbedSearchResultsRenderer')) {
      final scopes = ['library', 'uploads'];
      final tabIndex = (scope == null || filter != null) ? 0 : (scopes.indexOf(scope) + 1);
      results = nav(response['contents'], ['tabbedSearchResultsRenderer', 'tabs', tabIndex, 'tabRenderer', 'content']);
    } else if (response['contents'] is List) {
      return <dynamic>[]; // Return empty list if contents is a list at this level
    } else {
      results = response['contents'];
    }

    final sectionList = nav<List>(results, SECTION_LIST) ?? const [];
    if (sectionList.length == 1 && (sectionList.first as Map).containsKey('itemSectionRenderer')) return <dynamic>[];

    String? resultType;
    if (filter != null && filter.contains('playlists')) filter = 'playlists';
    if (scope == 'uploads') {
      filter = 'uploads';
      resultType = 'upload';
    }

    final apiSearchResultTypes = ps.API_RESULT_TYPES;
    final parsed = <dynamic>[];
    for (final res in sectionList.cast<Map>()) {
      String? category;
      List contents;
      if (res.containsKey('musicCardShelfRenderer')) {
        final topResult = ps.parseTopResult(
            res['musicCardShelfRenderer'] as Map<String, dynamic>, apiSearchResultTypes);
        parsed.add(topResult);
        contents = nav(res, ['musicCardShelfRenderer', 'contents'], noneIfAbsent: true) ?? const [];
        if (contents.isEmpty) continue;
        if ((contents.first as Map).containsKey('messageRenderer')) {
          category = nav<String>(contents.removeAt(0), ['messageRenderer', ...TEXT_RUN_TEXT]);
        }
      } else if (res.containsKey('musicShelfRenderer')) {
        contents = (res['musicShelfRenderer'] as Map)['contents'] as List;
        category = nav(res, [...MUSIC_SHELF, ...TITLE_TEXT], noneIfAbsent: true);
        if (filter != null && scope != 'uploads') {
          resultType = filter.substring(0, filter.length - 1).toLowerCase();
        }
      } else {
        continue;
      }
  
      parsed.addAll(ps.parseSearchResults(contents.cast<Map<String, dynamic>>(), apiSearchResultTypes, resultType: resultType, category: category));
      if (filter != null) {
        Future<Map<String, dynamic>> requestFunc(String additionalParams) async {
          final resp = await sendRequest('search', body, additionalParams: parseQueryString(additionalParams));
          return resp;
        }
        final more = await cont.getContinuations(
          res['musicShelfRenderer'] as Map<String, dynamic>,
          'musicShelfContinuation',
          limit - parsed.length,
          (additionalParams) => requestFunc(additionalParams),
          (List contents) => ps.parseSearchResults(contents, apiSearchResultTypes, resultType: resultType, category: category),
        );
        parsed.addAll(more);
      }
    }
    return parsed;
  }
}


