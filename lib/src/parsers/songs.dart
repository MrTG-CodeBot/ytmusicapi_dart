import '../navigation.dart';
import 'utils.dart';

typedef JsonDict = Map<String, dynamic>;
typedef JsonList = List<dynamic>;

List<Map<String, dynamic>> parseSongArtists(JsonDict data, int index) {
  final flexItem = getFlexColumnItem(data, index);
  if (flexItem == null) return [];
  final runs = (flexItem['text'] as Map)['runs'] as List;
  return parseSongArtistsRuns(runs);
}

List<Map<String, dynamic>> parseSongArtistsRuns(JsonList runs) {
  final artists = <Map<String, dynamic>>[];
  for (var j = 0; j <= runs.length ~/ 2; j++) {
    final run = runs[j * 2] as Map;
    artists.add({'name': run['text'], 'id': nav<String>(run, NAVIGATION_BROWSE_ID, noneIfAbsent: true)});
  }
  return artists;
}

Map<String, dynamic> parseSongRuns(JsonList runs) {
  final parsed = <String, dynamic>{'artists': <Map<String, dynamic>>[]};
  for (var i = 0; i < runs.length; i++) {
    if (i.isOdd) continue; // separators
    final run = runs[i] as Map;
    final text = run['text'] as String;
    if (run.containsKey('navigationEndpoint')) {
      final item = {'name': text, 'id': nav<String>(run, NAVIGATION_BROWSE_ID, noneIfAbsent: true)};
      if (item['id'] != null && ((item['id'] as String).startsWith('MPRE') || (item['id'] as String).contains('release_detail'))) {
        parsed['album'] = item;
      } else {
        (parsed['artists'] as List).add(item);
      }
    } else {
      if (RegExp(r'^\d([^ ])* [^ ]*$').hasMatch(text) && i > 0) {
        parsed['views'] = text.split(' ')[0];
      } else if (RegExp(r'^(\d+:)*\d+:\d+$').hasMatch(text)) {
        parsed['duration'] = text;
        parsed['duration_seconds'] = parseDuration(text);
      } else if (RegExp(r'^\d{4}$').hasMatch(text)) {
        parsed['year'] = text;
      } else {
        (parsed['artists'] as List).add({'name': text, 'id': null});
      }
    }
  }
  return parsed;
}

Map<String, dynamic>? parseSongAlbum(JsonDict data, int index) {
  final flexItem = getFlexColumnItem(data, index);
  if (flexItem == null) return null;
  final browseId = nav<String>(flexItem, [...TEXT_RUN, ...NAVIGATION_BROWSE_ID], noneIfAbsent: true);
  return {'name': getItemText(data, index), 'id': browseId};
}

bool parseSongLibraryStatus(JsonDict item) {
  final libraryStatus = nav<String>(item, [TOGGLE_MENU, 'defaultIcon', 'iconType'], noneIfAbsent: true);
  return libraryStatus == 'LIBRARY_SAVED';
}

Map<String, dynamic> parseSongMenuTokens(JsonDict item) {
  final toggleMenu = item[TOGGLE_MENU] as Map;
  var addToken = nav<String>(toggleMenu, ['defaultServiceEndpoint', ...FEEDBACK_TOKEN], noneIfAbsent: true);
  var removeToken = nav<String>(toggleMenu, ['toggledServiceEndpoint', ...FEEDBACK_TOKEN], noneIfAbsent: true);
  final inLibrary = parseSongLibraryStatus(item);
  if (inLibrary) {
    final tmp = addToken;
    addToken = removeToken;
    removeToken = tmp;
  }
  return {'add': addToken, 'remove': removeToken};
}

String parseLikeStatus(JsonDict service) {
  final status = ['LIKE', 'INDIFFERENT'];
  final idx = status.indexOf(((service['likeEndpoint'] as Map)['status'] as String));
  return status[idx - 1];
}

Map<String, dynamic> parseSong(JsonDict data) {
  final song = <String, dynamic>{
    'videoId': nav<String>(data, ['videoId'], noneIfAbsent: true) ??
        nav<String>(data, [
          'videoDetails',
          'videoId',
        ], noneIfAbsent: true) ??
        nav<String>(data, [
          'navigationEndpoint',
          'watchEndpoint',
          'videoId',
        ], noneIfAbsent: true),
    'title': nav<String>(data, [
      'videoDetails',
      'title',
    ]),
    'lengthMs': nav<String>(data, [
      'videoDetails',
      'lengthSeconds',
    ]),
    'channelId': nav<String>(data, [
      'videoDetails',
      'channelId',
    ]),
    'channelName': nav<String>(data, [
      'videoDetails',
      'author',
    ]),
    'thumbnailUrl': nav<List>(data, [
      'videoDetails',
      'thumbnail',
      'thumbnails',
    ]),
  };

  song['playabilityStatus'] = nav<Map<String, dynamic>>(data, ['playabilityStatus']);
  song['streamingData'] = nav<Map<String, dynamic>>(data, ['streamingData']);

  return song;
}


