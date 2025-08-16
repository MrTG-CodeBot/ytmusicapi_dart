import '../helpers.dart';
import '../navigation.dart';
import 'songs.dart';

typedef JsonDict = Map<String, dynamic>;

Map<String, dynamic> parseAlbumHeader(JsonDict response) {
  final header = nav<JsonDict>(response, HEADER_DETAIL)!;
  final album = <String, dynamic>{
    'title': nav<String>(header, TITLE_TEXT),
    'type': nav<String>(header, SUBTITLE),
    'thumbnails': nav<List>(header, THUMBNAIL_CROPPED),
    'isExplicit': nav(header, SUBTITLE_BADGE_LABEL, noneIfAbsent: true) != null,
  };
  if (header.containsKey('description')) {
    album['description'] = (header['description'] as Map)['runs'][0]['text'];
  }
  final albumInfo = parseSongRuns((header['subtitle'] as Map)['runs'].sublist(2));
  album.addAll(albumInfo);
  if (((header['secondSubtitle'] as Map)['runs'] as List).length > 1) {
    album['trackCount'] = toInt((header['secondSubtitle'] as Map)['runs'][0]['text'] as String);
    album['duration'] = (header['secondSubtitle'] as Map)['runs'][2]['text'];
  } else {
    album['duration'] = (header['secondSubtitle'] as Map)['runs'][0]['text'];
  }
  final menu = nav<JsonDict>(header, MENU)!;
  final toplevel = menu['topLevelButtons'] as List;
  album['audioPlaylistId'] = nav<String>(toplevel, [0, 'buttonRenderer', ...NAVIGATION_WATCH_PLAYLIST_ID],
      noneIfAbsent: true);
  album['audioPlaylistId'] ??= nav<String>(toplevel, [0, 'buttonRenderer', ...NAVIGATION_PLAYLIST_ID],
      noneIfAbsent: true);
  final service = nav<JsonDict>(toplevel, [1, 'buttonRenderer', 'defaultServiceEndpoint'], noneIfAbsent: true);
  if (service != null) {
    album['likeStatus'] = parseLikeStatus(service);
  }
  return album;
}

String? parseAlbumPlaylistIdIfExists(JsonDict? data) {
  if (data == null) return null;
  return nav<String>(data, WATCH_PID, noneIfAbsent: true)
      ?? nav<String>(data, WATCH_PLAYLIST_ID, noneIfAbsent: true);
}

Map<String, dynamic> parseAlbum(JsonDict data) {
  final album = <String, dynamic>{
    'title': nav<String>(data, [
      'header',
      'musicDetailHeaderRenderer',
      'title',
      'runs',
      0,
      'text',
    ]),
    'type': nav<String>(data, [
      'header',
      'musicDetailHeaderRenderer',
      'subtitle',
      'runs',
      0,
      'text',
    ]),
    'thumbnails': nav<List>(data, [
      'header',
      'musicDetailHeaderRenderer',
      'thumbnail',
      'thumbnails',
    ]),
    'description': nav<String>(data, [
      'header',
      'musicDetailHeaderRenderer',
      'description',
      'runs',
      0,
      'text',
    ], noneIfAbsent: true),
    'artists': parseSongArtistsRuns(
      nav<List>(data, [
        'header',
        'musicDetailHeaderRenderer',
        'subtitle',
        'runs',
      ])?.sublist(2) ?? [],
    ),
    'trackCount': nav<String>(data, [
      'header',
      'musicDetailHeaderRenderer',
      'secondSubtitle',
      'runs',
      0,
      'text',
    ], noneIfAbsent: true),
    'duration': nav<String>(data, [
      'header',
      'musicDetailHeaderRenderer',
      'secondSubtitle',
      'runs',
      2,
      'text',
    ], noneIfAbsent: true),
    'year': nav<String>(data, [
      'header',
      'musicDetailHeaderRenderer',
      'subtitle',
      'runs',
      (nav<List>(data, [
            'header',
            'musicDetailHeaderRenderer',
            'subtitle',
            'runs',
          ])?.length ?? 1) - 1,
      'text',
    ], noneIfAbsent: true),
  };

  final tracks = <Map<String, dynamic>>[];
  final musicShelf = nav<List>(data, [
    'contents',
    'singleColumnBrowseResultsRenderer',
    'tabs',
    0,
    'tabRenderer',
    'content',
    'sectionListRenderer',
    'contents',
    0,
    'musicShelfRenderer',
    'contents',
  ]) ?? [];

  for (final item in musicShelf) {
    final track = <String, dynamic>{
      'videoId': nav<String>(item, [
        'musicResponsiveListItemRenderer',
        'playNavigationEndpoint',
        'watchEndpoint',
        'videoId',
      ], noneIfAbsent: true),
      'title': nav<String>(item, [
        'musicResponsiveListItemRenderer',
        'flexColumns',
        0,
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
        0,
        'text',
      ]),
      'artists': parseSongArtists(item['musicResponsiveListItemRenderer'] as JsonDict, 1),
      'duration': nav<String>(item, [
        'musicResponsiveListItemRenderer',
        'flexColumns',
        1,
        'musicResponsiveListItemFlexColumnRenderer',
        'text',
        'runs',
        0,
        'text',
      ]),
      'thumbnails': nav<List>(item, [
        'musicResponsiveListItemRenderer',
        'thumbnail',
        'musicThumbnailRenderer',
        'thumbnail',
        'thumbnails',
      ]),
    };
    tracks.add(track);
  }
  album['tracks'] = tracks;
  return album;
}


