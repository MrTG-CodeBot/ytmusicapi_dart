import '../helpers.dart';
import '../navigation.dart';
import 'albums.dart';
import 'songs.dart';
import 'utils.dart';

typedef JsonDict = Map<String, dynamic>;
typedef JsonList = List<dynamic>;

const ALL_RESULT_TYPES = [
  'album',
  'artist',
  'playlist',
  'song',
  'video',
  'station',
  'profile',
  'podcast',
  'episode',
];
final API_RESULT_TYPES = ['single', 'ep', ...ALL_RESULT_TYPES];

String? getSearchResultType(String? resultTypeLocal, List<String> resultTypesLocal) {
  if (resultTypeLocal == null || resultTypeLocal.isEmpty) return null;
  final lower = resultTypeLocal.toLowerCase();
  if (!resultTypesLocal.contains(lower)) return 'album';
  return ALL_RESULT_TYPES[resultTypesLocal.indexOf(lower)];
}

Map<String, dynamic> parseTopResult(JsonDict data, List<String> searchResultTypes) {
  final resultType = getSearchResultType(nav<String>(data, SUBTITLE), searchResultTypes);
  final searchResult = <String, dynamic>{
    'category': nav<String>(data, CARD_SHELF_TITLE, noneIfAbsent: true),
    'resultType': resultType,
  };
  if (resultType == 'artist') {
    final subscribers = nav<String>(data, SUBTITLE2, noneIfAbsent: true);
    if (subscribers != null) searchResult['subscribers'] = subscribers.split(' ').first;
    final artistInfo = parseSongRuns(nav(data, ['title', 'runs']) as List);
    searchResult.addAll(artistInfo);
  }
  if (resultType == 'song' || resultType == 'video') {
    final onTap = data['onTap'] as Map?;
    if (onTap != null) {
      searchResult['videoId'] = nav<String>(onTap, WATCH_VIDEO_ID);
      searchResult['videoType'] = nav<String>(onTap, NAVIGATION_VIDEO_TYPE);
    }
  }
  if (resultType == 'song' || resultType == 'video' || resultType == 'album') {
    searchResult['videoId'] = nav<String>(data, ['onTap', ...WATCH_VIDEO_ID], noneIfAbsent: true);
    searchResult['videoType'] = nav<String>(data, ['onTap', ...NAVIGATION_VIDEO_TYPE], noneIfAbsent: true);
    searchResult['title'] = nav<String>(data, TITLE_TEXT);
    final runs = nav<List>(data, ['subtitle', 'runs']);
    final info = parseSongRuns((runs ?? const []).sublist(runs == null ? 0 : 2));
    searchResult.addAll(info);
  }
  if (resultType == 'album') {
    searchResult['browseId'] = nav<String>(data, [...TITLE, ...NAVIGATION_BROWSE_ID], noneIfAbsent: true);
    final buttonCommand = nav<dynamic>(data, ['buttons', 0, 'buttonRenderer', 'command'], noneIfAbsent: true);
    searchResult['playlistId'] = parseAlbumPlaylistIdIfExists(buttonCommand is JsonDict ? buttonCommand : null);
  }
  if (resultType == 'playlist') {
    searchResult['playlistId'] = nav<String>(data, MENU_PLAYLIST_ID);
    searchResult['title'] = nav<String>(data, TITLE_TEXT);
    final runs = nav<List>(data, ['subtitle', 'runs']) ?? const [];
    searchResult['author'] = parseSongArtistsRuns(runs.length >= 3 ? runs.sublist(2) : const []);
  }
  if (resultType == 'episode') {
    searchResult['videoId'] = nav<String>(data, [...THUMBNAIL_OVERLAY_NAVIGATION, ...WATCH_VIDEO_ID]);
    searchResult['videoType'] = nav<String>(data, [...THUMBNAIL_OVERLAY_NAVIGATION, ...NAVIGATION_VIDEO_TYPE]);
    final subtitleRuns = nav<List>(data, SUBTITLE_RUNS) ?? const [];
    final runs = subtitleRuns.length >= 3 ? subtitleRuns.sublist(2) : const [];
    searchResult['date'] = (runs.first as Map)['text'];
    searchResult['podcast'] = parseIdName(runs[2] as Map<String, dynamic>);
  }
  searchResult['thumbnails'] = nav<List>(data, THUMBNAILS, noneIfAbsent: true);

  return searchResult;
}

Map<String, dynamic> parseSearchResult(
  JsonDict data,
  List<String> apiSearchResultTypes,
  String? resultType,
  String? category,
) {
  final defaultOffset = ((resultType == null || resultType == 'album') ? 1 : 0) * 2;
  final searchResult = <String, dynamic>{'category': category};

  final videoType = nav<String>(
    data,
    [...PLAY_BUTTON, 'playNavigationEndpoint', ...NAVIGATION_VIDEO_TYPE],
    noneIfAbsent: true,
  );

  if (resultType == null) {
    final browseId = nav<String>(data, NAVIGATION_BROWSE_ID, noneIfAbsent: true);
    if (browseId != null) {
      final mapping = {
        'VM': 'playlist',
        'RD': 'playlist',
        'VL': 'playlist',
        'MPLA': 'artist',
        'MPRE': 'album',
        'MPSP': 'podcast',
        'MPED': 'episode',
        'UC': 'artist',
      };
      resultType = mapping.entries
          .firstWhere((e) => browseId.startsWith(e.key), orElse: () => const MapEntry('', ''))
          .value;
      if (resultType.isEmpty) {
        resultType = {
          'MUSIC_VIDEO_TYPE_ATV': 'song',
          'MUSIC_VIDEO_TYPE_PODCAST_EPISODE': 'episode',
        }[videoType ?? ''] ?? 'video';
      }
    } else {
      resultType = {
        'MUSIC_VIDEO_TYPE_ATV': 'song',
        'MUSIC_VIDEO_TYPE_PODCAST_EPISODE': 'episode',
      }[videoType ?? ''] ?? 'video';
    }
  }
  searchResult['resultType'] = resultType;

  if (resultType != 'artist') {
    searchResult['title'] = getItemText(data, 0);
  }
  if (resultType == 'artist') {
    searchResult['artist'] = getItemText(data, 0);
    parseMenuPlaylists(data, searchResult);
  } else if (resultType == 'album') {
    searchResult['type'] = getItemText(data, 1);
    final playNavigation = nav<JsonDict>(data, [...PLAY_BUTTON, 'playNavigationEndpoint'], noneIfAbsent: true);
    searchResult['playlistId'] = parseAlbumPlaylistIdIfExists(playNavigation);
  } else if (resultType == 'playlist') {
    final flexItem = nav<JsonDict>(getFlexColumnItem(data, 1), TEXT_RUNS);
    final runs = (flexItem != null) ? ((flexItem['runs'] as List?) ?? const []) : const [];
    final hasAuthor = runs.length == defaultOffset + 3;
    var itemCount = (getItemText(data, 1, runIndex: defaultOffset + (hasAuthor ? 2 : 0)) ?? '').split(' ').first;
    if (itemCount.isNotEmpty && int.tryParse(itemCount) != null) {
      itemCount = toInt(itemCount).toString();
    }
    searchResult['itemCount'] = itemCount;
    searchResult['author'] = hasAuthor ? getItemText(data, 1, runIndex: defaultOffset) : null;
  } else if (resultType == 'station') {
    searchResult['videoId'] = nav<String>(data, NAVIGATION_VIDEO_ID);
    searchResult['playlistId'] = nav<String>(data, NAVIGATION_PLAYLIST_ID);
  } else if (resultType == 'profile') {
    searchResult['name'] = getItemText(data, 1, runIndex: 2, noneIfAbsent: true);
  } else if (resultType == 'song') {
    searchResult['album'] = null;
    if (data.containsKey('menu')) {
      final toggleMenu = findObjectByKey(nav(data, MENU_ITEMS)!, TOGGLE_MENU);
      if (toggleMenu != null) {
        searchResult['inLibrary'] = parseSongLibraryStatus(toggleMenu);
        searchResult['feedbackTokens'] = parseSongMenuTokens(toggleMenu);
      }
    }
  } else if (resultType == 'upload') {
    final browseId = nav<String>(data, NAVIGATION_BROWSE_ID, noneIfAbsent: true);
    if (browseId == null) {
      final flexItems = [
        nav<List>(getFlexColumnItem(data, 0), ['text', 'runs'], noneIfAbsent: true),
        nav<List>(getFlexColumnItem(data, 1), ['text', 'runs'], noneIfAbsent: true),
      ];
      if (flexItems[0] != null) {
        searchResult['videoId'] = nav<String>(flexItems[0]![0], NAVIGATION_VIDEO_ID, noneIfAbsent: true);
        searchResult['playlistId'] = nav<String>(flexItems[0]![0], NAVIGATION_PLAYLIST_ID, noneIfAbsent: true);
      }
      if (flexItems[1] != null) {
        searchResult.addAll(parseSongRuns(flexItems[1]!));
      }
      searchResult['resultType'] = 'song';
    } else {
      searchResult['browseId'] = browseId;
      if (searchResult['browseId'].toString().contains('artist')) {
        searchResult['resultType'] = 'artist';
      } else {
        final flexItem2 = getFlexColumnItem(data, 1);
        final runs = flexItem2 != null
            ? (flexItem2['text'] as Map)['runs'].where((e) => (e as Map).containsKey('text')).toList()
            : <dynamic>[];
        if (runs.length > 1) searchResult['artist'] = (runs[1] as Map)['text'];
        if (runs.length > 2) searchResult['releaseDate'] = (runs[2] as Map)['text'];
        searchResult['resultType'] = 'album';
      }
    }
  }

  if (['song', 'video', 'episode'].contains(resultType)) {
    searchResult['videoId'] = nav<String>(data, [...PLAY_BUTTON, 'playNavigationEndpoint', 'watchEndpoint', 'videoId'],
        noneIfAbsent: true);
    searchResult['videoType'] = videoType;
  }
  if (['song', 'video', 'album'].contains(resultType)) {
    searchResult['duration'] = null;
    searchResult['year'] = null;
    final flexItem = getFlexColumnItem(data, 1)!;
    final runs = (flexItem['text'] as Map)['runs'] as List;
    final flexItem2 = getFlexColumnItem(data, 2);
    if (flexItem2 != null) {
      final runs2 = (flexItem2['text'] as Map)['runs'] as List;
      runs.add({'text': ''});
      runs.addAll(runs2);
    }
    final runsOffset = ((runs.first as Map).length == 1 && API_RESULT_TYPES.contains(((runs.first as Map)['text'] as String).toLowerCase())) ? 2 : 0;
    final info = parseSongRuns(runs.sublist(runsOffset));
    searchResult.addAll(info);
  }
  if (['artist', 'album', 'playlist', 'profile', 'podcast'].contains(resultType)) {
    searchResult['browseId'] = nav<String>(data, NAVIGATION_BROWSE_ID, noneIfAbsent: true);
  }
  if (['song', 'album'].contains(resultType)) {
    searchResult['isExplicit'] = nav(data, BADGE_LABEL, noneIfAbsent: true) != null;
  }
  if (resultType == 'episode') {
    final flexItem = getFlexColumnItem(data, 1)!;
    final runs = nav<List>(flexItem, TEXT_RUNS)!.sublist(defaultOffset);
    final hasDate = runs.length > 1 ? 1 : 0;
    searchResult['live'] = nav(data, ['badges', 0, 'liveBadgeRenderer'], noneIfAbsent: true) != null;
    if (hasDate == 1) searchResult['date'] = (runs[0] as Map)['text'];
    searchResult['podcast'] = parseIdName(runs[hasDate * 2] as Map<String, dynamic>);
  }
  searchResult['thumbnails'] = nav<List>(data, THUMBNAILS, noneIfAbsent: true);
  return searchResult;
}

List<Map<String, dynamic>> parseSearchResults(
  List results,
  List<String> apiSearchResultTypes,
  {String? resultType,
  String? category}
) {
  return results
      .where((e) => e is Map)
      .expand((e) {
        dynamic content = (e as Map)[MRLIR];
        if (content is Map && content.containsKey('contents')) {
          content = content['contents'];
        }
        if (content is List) {
          return content.where((item) => item is Map).map((item) {
              
              if (item is Map<String, dynamic>) {
                try {
                  final parsedItem = parseSearchResult(item, apiSearchResultTypes, resultType, category);
                  return parsedItem;
                } catch (e, st) {
                  print('Error parsing search result item: $e\n$st');
                  return null;
                }
              } else {
                return null; // Or handle this case appropriately, e.g., log and skip
               }
           }).where((item) => item != null).cast<Map<String, dynamic>>();
        } else if (content is Map) {
          return [parseSearchResult(content as Map<String, dynamic>, apiSearchResultTypes, resultType, category)];
        }
        return <Map<String, dynamic>>[];
      })
      .toList();
}


