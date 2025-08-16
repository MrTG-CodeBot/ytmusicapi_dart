import 'package:dart_ytmusicapi/dart_ytmusicapi.dart';
import 'dart:convert'; // Add this import for JsonEncoder

void main() async {
  final yt = YTMusic();

  // Get playlist details using playlist ID
  print('Getting playlist details for a specific playlist ID...');
  try {
    final playlistId = 'OLAK5uy_nfyuG_kOuhKtKOmf6tMlaJBieV1julZBc'; // Replace with a real playlist ID
    final playlistDetails = await yt.getPlaylist(playlistId);

    print("Playlist Details:");
    print("${JsonEncoder.withIndent('  ').convert(playlistDetails)}");
    print('------------------------------------');
  } catch (e) {
    print('Error getting playlist details: $e');
  }
}
