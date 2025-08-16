import 'package:dart_ytmusicapi/src/exceptions.dart';
import 'package:dart_ytmusicapi/src/navigation.dart' as Navigation;
import 'package:dart_ytmusicapi/src/ytmusic_base.dart';
import 'package:dart_ytmusicapi/src/models/lyrics.dart';

mixin LyricsMixin on YTMusicBase {
  @override
  Future<Map<String, dynamic>> sendRequest(String endpoint, Map<String, dynamic> body, {Map<String, String>? additionalParams})
  {
    return super.sendRequest(endpoint, body, additionalParams: additionalParams);
  }
  Future<Lyrics?> getLyrics(String browseId, {bool timestamps = false}) async {
    if (browseId.isEmpty) {
      throw YTMusicUserError('Invalid browseId provided. This song might not have lyrics.');
    }

    Map<String, dynamic> response;
    if (timestamps) {
      asMobile();
      response = await super.sendRequest('browse', {'browseId': browseId}, additionalParams: null);
      asWeb();
    } else {
      response = await super.sendRequest('browse', {'browseId': browseId}, additionalParams: null);
    }

    Lyrics? lyrics;
    if (timestamps && Navigation.nav(response, Navigation.TIMESTAMPED_LYRICS, noneIfAbsent: true) != null) {
      final data = Navigation.nav(response, Navigation.TIMESTAMPED_LYRICS, noneIfAbsent: true);
      if (data == null || !data.containsKey('timedLyricsData')) {
        return null;
      }
      lyrics = TimedLyrics(
        lines: (data['timedLyricsData'] as List)
            .map((item) => LyricLine.fromJson(item as Map<String, dynamic>))
            .toList(),
        source: data['sourceMessage'],
        hasTimestamps: true,
      );
    } else {
      final List<dynamic> lyricsPath = [];
      lyricsPath.addAll(Navigation.CONTENT);
      lyricsPath.addAll(Navigation.SECTION_LIST_ITEM);
      lyricsPath.addAll(Navigation.DESCRIPTION_SHELF);
      lyricsPath.addAll(Navigation.DESCRIPTION);
      final lyricsStr = Navigation.nav(response, lyricsPath, noneIfAbsent: true);
      if (lyricsStr == null) {
        return null;
      }
      final List<dynamic> sourcePath = [];
      sourcePath.addAll(Navigation.CONTENT);
      sourcePath.addAll(Navigation.SECTION_LIST_ITEM);
      sourcePath.addAll(Navigation.DESCRIPTION_SHELF);
      sourcePath.addAll(Navigation.RUN_TEXT);
      final sourceStr = Navigation.nav(response, sourcePath, noneIfAbsent: true);
      lyrics = Lyrics(
        lyrics: lyricsStr,
        source: sourceStr,
        hasTimestamps: false,
      );
    }

    return lyrics;
  }
}