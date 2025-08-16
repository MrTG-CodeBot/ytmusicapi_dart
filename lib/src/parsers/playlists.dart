import 'dart:core';

import '../helpers.dart';
import '../navigation.dart';
import 'songs.dart';
import 'utils.dart';

typedef JsonDict = Map<String, dynamic>;
typedef JsonList = List<dynamic>;

JsonDict parsePlaylistHeader(JsonDict response) {
  final playlist = <String, dynamic>{};
  final editableHeader = nav<JsonDict>(response, [...HEADER, ...EDITABLE_PLAYLIST_DETAIL_HEADER],
      noneIfAbsent: true);
  playlist['owned'] = editableHeader != null;
  playlist['privacy'] = 'PUBLIC';
  JsonDict header;
  if (editableHeader != null) {
    header = nav<JsonDict>(editableHeader, HEADER_DETAIL)!;
    playlist['privacy'] = (editableHeader['editHeader'] as Map)['musicPlaylistEditHeaderRenderer']['privacy'];
  } else {
    header = nav<JsonDict>(response, HEADER_DETAIL, noneIfAbsent: true) ??
        nav(response, [...TWO_COLUMN_RENDERER, ...TAB_CONTENT, ...SECTION_LIST_ITEM, ...RESPONSIVE_HEADER])!;
  }
  playlist.addAll(parsePlaylistHeaderMeta(header));
  playlist['thumbnails'] ??= nav(header, THUMBNAILS, noneIfAbsent: true);
  playlist['description'] = nav(header, DESCRIPTION, noneIfAbsent: true);
  final runs = nav<List>(header, SUBTITLE_RUNS) ?? const [];
  if (runs.length > 1) {
    playlist['author'] = {
      'name': nav<String>(header, SUBTITLE2),
      'id': nav<String>(header, [...SUBTITLE_RUNS, 2, ...NAVIGATION_BROWSE_ID], noneIfAbsent: true),
    };
    if (runs.length == 5) playlist['year'] = nav<String>(header, SUBTITLE3);
  }
  return playlist;
}

JsonDict parsePlaylistHeaderMeta(JsonDict header) {
  final playlistMeta = <String, dynamic>{
    'views': null,
    'duration': null,
    'trackCount': null,
    'title': ((header['title'] as Map?)?['runs'] as List? ?? const [])
        .map((e) => (e as Map)['text'] as String)
        .join(),
    'thumbnails': nav(header, THUMBNAILS),
  };
  if ((header['secondSubtitle'] as Map).containsKey('runs')) {
    final runs = (header['secondSubtitle'] as Map)['runs'] as List;
    final hasViews = (runs.length > 3) ? 2 : 0;
    playlistMeta['views'] = hasViews == 0 ? null : toInt(runs[0]['text'] as String);
    final hasDuration = (runs.length > 1) ? 2 : 0;
    playlistMeta['duration'] = hasDuration == 0 ? null : runs[hasViews + hasDuration]['text'];
    final songCountText = runs[hasViews + 0]['text'] as String;
    final songCountDigits = RegExp(r"\d+").allMatches(songCountText).map((m) => m.group(0)!).join();
    playlistMeta['trackCount'] = songCountDigits.isNotEmpty ? toInt(songCountDigits) : null;
  }
  return playlistMeta;
}

JsonDict parseAudioPlaylist(
  JsonDict response,
  int? limit,
  Future<JsonDict> Function(JsonDict body) requestFunc,
) {
  final playlist = <String, dynamic>{
    'owned': false,
    'privacy': 'PUBLIC',
    'description': null,
    'views': null,
    'duration': null,
    'tracks': <dynamic>[],
    'thumbnails': <dynamic>[],
    'related': <dynamic>[],
  };
  final sectionList = nav<JsonDict>(response, [...TWO_COLUMN_RENDERER, 'secondaryContents', ...SECTION])!;
  final contentData = nav<JsonDict>(sectionList, [...CONTENT, 'musicPlaylistShelfRenderer'])!;
  playlist['id'] = nav(contentData, [...CONTENT, MRLIR, ...PLAY_BUTTON, 'playNavigationEndpoint', ...WATCH_PLAYLIST_ID]);
  playlist['trackCount'] = contentData['collapsedItemCount'];
  playlist['tracks'] = [];
  if (contentData.containsKey('contents')) {
    playlist['tracks'] = parsePlaylistItems(contentData['contents'] as List);
    // Continuations 2025 handled in mixin using helper
  }
  final tracks = playlist['tracks'] as List;
  if (tracks.isNotEmpty) {
    playlist['title'] = (tracks.first)['album']['name'];
  }
  playlist['duration_seconds'] = sumTotalDuration(playlist);
  return playlist;
}

List<Map<String, dynamic>> parsePlaylistItems(
  List results, {
  List<List<String>>? menuEntries,
  bool isAlbum = false,
}) {
  final songs = <Map<String, dynamic>>[];
  for (final result in results) {
    final mrliRenderer = (result as Map)[MRLIR];
    if (mrliRenderer is List) {
      for (final item in mrliRenderer.whereType<Map<String, dynamic>>()) {
        final song = parsePlaylistItem(item, menuEntries: menuEntries, isAlbum: isAlbum);
        if (song != null) songs.add(song);
      }
    } else if (mrliRenderer is Map<String, dynamic>) {
      final song = parsePlaylistItem(mrliRenderer, menuEntries: menuEntries, isAlbum: isAlbum);
      if (song != null) songs.add(song);
    }
  }
  return songs;
}

Map<String, dynamic>? parsePlaylistItem(
  JsonDict data, {
  List<List<String>>? menuEntries,
  bool isAlbum = false,
}) {
  String? videoId;
  String? setVideoId;
  String? like;
  Map<String, dynamic>? feedbackTokens;
  bool? libraryStatus;

  if (data.containsKey('menu')) {
    for (final item in nav<List>(data, MENU_ITEMS) ?? const []) {
      if ((item as Map).containsKey('menuServiceItemRenderer')) {
        final menuService = nav(item, MENU_SERVICE) as Map?;
        if (menuService != null && menuService.containsKey('playlistEditEndpoint')) {
          setVideoId = nav(menuService, ['playlistEditEndpoint', 'actions', 0, 'setVideoId'], noneIfAbsent: true);
          videoId = nav(menuService, ['playlistEditEndpoint', 'actions', 0, 'removedVideoId'], noneIfAbsent: true);
        }
      }
      if (item.containsKey(TOGGLE_MENU)) {
        final typed = item.cast<String, dynamic>();
        feedbackTokens = parseSongMenuTokens(typed);
        libraryStatus = parseSongLibraryStatus(typed);
      }
    }
  }

  if (nav(data, PLAY_BUTTON, noneIfAbsent: true) != null) {
    if (nav(data, PLAY_BUTTON) is Map && (nav(data, PLAY_BUTTON) as Map).containsKey('playNavigationEndpoint')) {
      videoId = (((nav(data, PLAY_BUTTON) as Map)['playNavigationEndpoint'] as Map)['watchEndpoint'] as Map)['videoId']
          as String?;
      if (data.containsKey('menu')) {
        like = nav<String>(data, MENU_LIKE_STATUS, noneIfAbsent: true);
      }
    }
  }

  var isAvailable = true;
  if (data.containsKey('musicItemRendererDisplayPolicy')) {
    isAvailable = data['musicItemRendererDisplayPolicy'] != 'MUSIC_ITEM_RENDERER_DISPLAY_POLICY_GREY_OUT';
  }

  final usePreset = (!isAvailable || isAlbum) ? true : null;
  int? titleIndex = usePreset == true ? 0 : null;
  int? artistIndex = usePreset == true ? 1 : null;
  int? albumIndex = usePreset == true ? 2 : null;
  final userChannelIndexes = <int>[];
  int? unrecognizedIndex;

  for (var index = 0; index < (data['flexColumns'] as List).length; index++) {
    final flexColumnItem = getFlexColumnItem(data, index);
    final navigationEndpoint = nav(flexColumnItem, [...TEXT_RUN, 'navigationEndpoint'], noneIfAbsent: true);
    if (navigationEndpoint == null) {
      if (nav(flexColumnItem, TEXT_RUN_TEXT, noneIfAbsent: true) != null) {
        unrecognizedIndex = unrecognizedIndex ?? index;
      }
      continue;
    }
    if ((navigationEndpoint as Map).containsKey('watchEndpoint')) {
      titleIndex = index;
    } else if (navigationEndpoint.containsKey('browseEndpoint')) {
      final pageType = nav(navigationEndpoint, [
        'browseEndpoint',
        ...PAGE_TYPE,
      ]);
      if (pageType == 'MUSIC_PAGE_TYPE_ARTIST' || pageType == 'MUSIC_PAGE_TYPE_UNKNOWN') {
        artistIndex = index;
      } else if (pageType == 'MUSIC_PAGE_TYPE_ALBUM') {
        albumIndex = index;
      } else if (pageType == 'MUSIC_PAGE_TYPE_USER_CHANNEL') {
        userChannelIndexes.add(index);
      } else if (pageType == 'MUSIC_PAGE_TYPE_NON_MUSIC_AUDIO_TRACK_PAGE') {
        titleIndex = index;
      }
    }
  }

  if (artistIndex == null && unrecognizedIndex != null) {
    artistIndex = unrecognizedIndex;
  }
  if (artistIndex == null && userChannelIndexes.isNotEmpty) {
    artistIndex = userChannelIndexes.last;
  }

  final title = titleIndex != null ? getItemText(data, titleIndex) : null;
  if (title == 'Song deleted') return null;
  final artists = artistIndex != null ? parseSongArtists(data, artistIndex) : null;
  final album = albumIndex != null ? parseSongAlbum(data, albumIndex) : null;
  final views = isAlbum ? getItemText(data, 2) : null;

  String? duration;
  if (data.containsKey('fixedColumns')) {
    final fixed = getFixedColumnItem(data, 0);
    if (fixed != null && nav(fixed, ['text'], noneIfAbsent: true) is Map &&
        (nav(fixed, ['text']) as Map).containsKey('simpleText')) {
      duration = nav<String>(fixed, ['text', 'simpleText']);
    } else {
      duration = nav<String>(fixed, TEXT_RUN_TEXT, noneIfAbsent: true);
    }
  }

  final thumbnails = nav<List>(data, THUMBNAILS, noneIfAbsent: true);
  final isExplicit = nav(data, BADGE_LABEL, noneIfAbsent: true) != null;
  final videoType = nav<String>(data, [...MENU_ITEMS, 0, MNIR, 'navigationEndpoint', ...NAVIGATION_VIDEO_TYPE],
      noneIfAbsent: true);

  final song = <String, dynamic>{
    'videoId': videoId,
    'title': title,
    'artists': artists,
    'album': album,
    'likeStatus': like,
    'inLibrary': libraryStatus,
    'thumbnails': thumbnails,
    'isAvailable': isAvailable,
    'isExplicit': isExplicit,
    'videoType': videoType,
    'views': views,
  };

  if (isAlbum) {
    song['trackNumber'] = isAvailable ? int.parse(nav(data, ['index', 'runs', 0, 'text']) as String) : null;
  }
  if (duration != null) {
    song['duration'] = duration;
    song['duration_seconds'] = parseDuration(duration);
  }
  if (setVideoId != null) song['setVideoId'] = setVideoId;
  if (feedbackTokens != null) song['feedbackTokens'] = feedbackTokens;

  if (menuEntries != null) {
    final menuItems = nav<List>(data, MENU_ITEMS) ?? const [];
    for (final entry in menuEntries) {
      final items = findObjectsByKey(menuItems, entry[0]);
      song[entry.last] = items
          .map((itm) => nav(itm, entry, noneIfAbsent: true))
          .firstWhere((element) => element != null, orElse: () => null);
    }
  }
  return song;
}

String validatePlaylistId(String playlistId) => playlistId.startsWith('VL') ? playlistId.substring(2) : playlistId;


