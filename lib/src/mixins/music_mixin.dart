import '../ytmusic_base.dart';
import '../navigation.dart';
import '../parsers/songs.dart' as psongs;
import '../parsers/albums.dart' as palbums;

mixin MusicMixin on YTMusicBase {
  Future<Map<String, dynamic>> getSong(String videoId) async {
    final body = {'videoId': videoId};
    final response = await sendRequest('player', body);
    return psongs.parseSong(response);
  }

  Future<Map<String, dynamic>> getAlbum(String browseId) async {
    final body = {'browseId': browseId};
    final response = await sendRequest('browse', body);
    return palbums.parseAlbum(response);
  }


}
