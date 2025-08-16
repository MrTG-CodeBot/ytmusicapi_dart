import 'dart:convert';

import 'package:dart_ytmusicapi/dart_ytmusicapi.dart' as constants;
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'package:crypto/crypto.dart' as crypto;

Map<String, String> initializeHeaders([String? userAgent]) {
  return {
    'user-agent': userAgent ?? constants.userAgent,
    'accept': '*/*',
    'accept-encoding': 'gzip, deflate',
    'content-type': 'application/json',
    'content-encoding': 'gzip',
    'origin': ytmDomain,
  };
}

Map<String, dynamic> initializeContext() {
  final date = DateTime.now().toUtc();
  final yyyymmdd = date.toIso8601String().substring(0, 10).replaceAll('-', '');
  return {
    'context': {
      'client': {
        'clientName': 'WEB_REMIX',
        'clientVersion': '1.$yyyymmdd.01.00',
      },
      'user': {},
    }
  };
}

Future<Map<String, String>> getVisitorId(Future<http.Response> Function(String) requestFunc) async {
  final response = await requestFunc(ytmDomain);
  final matches = RegExp(r"ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;")
      .allMatches(response.body)
      .toList();
  var visitorId = '';
  if (matches.isNotEmpty) {
    final cfg = json.decode(matches.first.group(1)!) as Map<String, dynamic>;
    visitorId = (cfg['VISITOR_DATA'] as String?) ?? '';
  }
  return {'X-Goog-Visitor-Id': visitorId};
}

String getAuthorization(String auth) {
  final unixTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  final content = utf8.encode('$unixTimestamp $auth');
  final digest = crypto.sha1.convert(content).toString();
  return 'SAPISIDHASH ${unixTimestamp}_$digest';
}

int toInt(String string) {
  final numberString = string.replaceAll(RegExp(r'\D'), '');
  return int.parse(numberString);
}

int sumTotalDuration(Map<String, dynamic> item) {
  if (!item.containsKey('tracks')) return 0;
  final tracks = (item['tracks'] as List?) ?? const [];
  var total = 0;
  for (final track in tracks.cast<Map<String, dynamic>>()) {
    final value = track['duration_seconds'];
    if (value is int) total += value;
  }
  return total;
}


