import 'dart:convert';
import 'package:dart_ytmusicapi/dart_ytmusicapi.dart';

void main() async {
  final yt = YTMusic();
  final playlistId = 'OLAK5uy_n3d2BRXHsWj4U-74AOMAyqVeo6SbB5Ebk'; // Replace with a valid playlist ID

  print('Getting playlist with ID: $playlistId');

  try {
    final playlist = await yt.getPlaylist(playlistId);
    print('Playlist details:');
    print("${JsonEncoder.withIndent('  ').convert(playlist)}");
  } catch (e) {
    print('An error occurred: $e');
  }
}