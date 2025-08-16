import '../continuations.dart' as cont;
import '../helpers.dart';
import '../navigation.dart';
import '../parsers/playlists.dart' as pp;
import '../parsers/songs.dart';
import '../continuations.dart';
import '../ytmusic_base.dart';

typedef JsonDict = Map<String, dynamic>;

mixin PlaylistsMixin on YTMusicBase {
  Future<Map<String, dynamic>> getPlaylist(String playlistId,
      {int? limit = 100, bool related = false, int suggestionsLimit = 0}) async {
    final browseId = playlistId.startsWith('VL') ? playlistId : 'VL$playlistId';
    final body = {'browseId': browseId};
    final endpoint = 'browse';
    Future<Map<String, dynamic>> requestFunc(String? additionalParams) async {
      return await sendRequest(endpoint, body, additionalParams: parseQueryString(additionalParams));
    }
    final response = await requestFunc(null);

    Future<Map<String, dynamic>> requestFuncBody(Map<String, dynamic> reqBody) async {
      return await sendRequest(endpoint, reqBody);
    }

    if (playlistId.startsWith('OLA') || playlistId.startsWith('VLOLA')) {
      final parsed = pp.parseAudioPlaylist(response, limit, requestFuncBody);
      // fetch 2025 continuations for audio playlists
      final sectionList = nav(response, [...TWO_COLUMN_RENDERER, 'secondaryContents', ...SECTION]);
      final contentData = nav(sectionList, [...CONTENT, 'musicPlaylistShelfRenderer']);
      if (contentData is Map && contentData.containsKey('contents')) {
        final more = await cont.getContinuations2025(
            contentData as Map<String, dynamic>,
            limit,
            (reqBody) => sendRequest(endpoint, reqBody),
            (List contents) => pp.parsePlaylistItems(contents));
        (parsed['tracks'] as List).addAll(more);
      }
      parsed['duration_seconds'] = sumTotalDuration(parsed);
      return parsed;
    }

    final headerData = nav(response, [...TWO_COLUMN_RENDERER, ...TAB_CONTENT, ...SECTION_LIST_ITEM]);
    final sectionList = nav(response, [...TWO_COLUMN_RENDERER, 'secondaryContents', ...SECTION]);
    final owned = EDITABLE_PLAYLIST_DETAIL_HEADER[0];
    final playlist = <String, dynamic>{};
    playlist['owned'] = (headerData as Map).containsKey(owned);
    late Map<String, dynamic> header;
    if (!playlist['owned']) {
      header = nav(headerData, RESPONSIVE_HEADER)! as Map<String, dynamic>;
      playlist['id'] = nav(header, ['buttons', 1, 'musicPlayButtonRenderer', 'playNavigationEndpoint', ...WATCH_PLAYLIST_ID],
          noneIfAbsent: true);
      playlist['privacy'] = 'PUBLIC';
    } else {
      playlist['id'] = nav(headerData, [...EDITABLE_PLAYLIST_DETAIL_HEADER, ...PLAYLIST_ID]);
      header = nav(headerData, [...EDITABLE_PLAYLIST_DETAIL_HEADER, ...HEADER, ...RESPONSIVE_HEADER])!;
      playlist['privacy'] = (headerData[EDITABLE_PLAYLIST_DETAIL_HEADER[0]]['editHeader']
          ['musicPlaylistEditHeaderRenderer']['privacy']);
    }
    final descriptionShelf = nav(header, ['description', ...DESCRIPTION_SHELF], noneIfAbsent: true);
    playlist['description'] = descriptionShelf == null
        ? null
        : ((descriptionShelf['description']['runs'] as List).map((e) => e['text']).join());
    playlist.addAll(pp.parsePlaylistHeaderMeta(header));
    final subtitleRuns = nav<List>(header, SUBTITLE_RUNS) ?? const [];
    final offset = (playlist['owned'] == true) ? 2 : 0;
    if (subtitleRuns.length > 2 + offset) {
      final runs = subtitleRuns.sublist(2 + offset);
      final songInfo = parseSongRuns(runs);
      playlist.addAll(songInfo);
    }

    playlist['related'] = <dynamic>[];
    if (sectionList is Map && sectionList.containsKey('continuations')) {
      var additionalParams = getContinuationParams(sectionList as Map<String, dynamic>);
      if (playlist['owned'] == true && (suggestionsLimit > 0 || related)) {
        final suggested = await requestFunc(additionalParams);
        final continuation = nav(suggested, SECTION_LIST_CONTINUATION);
        additionalParams = getContinuationParams(continuation as Map<String, dynamic>);
        final suggestionsShelf = nav(continuation, [...CONTENT, ...MUSIC_SHELF]) as Map<String, dynamic>;
        playlist['suggestions'] = getContinuationContents(suggestionsShelf);
        final moreSuggestions = await getReloadableContinuations(
            suggestionsShelf, 'musicShelfContinuation', suggestionsLimit - (playlist['suggestions'] as List).length,
            (additionalParams) => requestFunc(additionalParams!),
            (List contents) => pp.parsePlaylistItems(contents));
        (playlist['suggestions'] as List).addAll(moreSuggestions);
      }
      if (related) {
        final resp2 = await requestFunc(additionalParams);
        final continuation = nav(resp2, SECTION_LIST_CONTINUATION, noneIfAbsent: true);
        if (continuation != null) {
          final carousel = nav(continuation, [...CONTENT, ...CAROUSEL]);
          playlist['related'] = getContinuationContents(carousel as Map<String, dynamic>);
        }
      }
    }

    playlist['tracks'] = <dynamic>[];
    final contentData = nav(sectionList, [...CONTENT, 'musicPlaylistShelfRenderer']) as Map<String, dynamic>;
    if (contentData.containsKey('contents')) {
      playlist['tracks'] = pp.parsePlaylistItems(contentData['contents'] as List);
      final more = await cont.getContinuations2025(
          contentData, limit, (reqBody) => sendRequest(endpoint, reqBody), (List contents) => pp.parsePlaylistItems(contents));
      (playlist['tracks'] as List).addAll(more);
    }
    playlist['duration_seconds'] = sumTotalDuration(playlist);
    return playlist;
  }
}


