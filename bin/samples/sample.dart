import 'dart:convert';
import 'dart:io';

import 'package:dart_ytmusicapi/dart_ytmusicapi.dart';

Future<void> main() async {
  final yt = YTMusic();

    final songDetails = await yt.getSong('t7akpsiyq_4');
    print(JsonEncoder.withIndent('  ').convert(songDetails));
}