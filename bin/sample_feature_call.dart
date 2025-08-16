import 'dart:convert';

import 'package:dart_ytmusicapi/dart_ytmusicapi.dart';

void main() async {
  // Initialize YTMusicAPI
  final yt = YTMusic();

  // Example 1: Search for a song
  print('Searching for "Bohemian Rhapsody" by Queen...');
  final searchResults = await yt.search(query: 'Never Gonna Give You Up', filter: 'songs');

  if (searchResults != null && searchResults.isNotEmpty) {
    print("${JsonEncoder.withIndent('  ').convert(searchResults)}");
  } else {
    print('No songs found.');
  }

  
}