import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_types.dart';
import 'constants.dart';
import 'exceptions.dart';
import 'helpers.dart';
import 'oauth/token.dart';
import 'models/lyrics.dart';

class YTMusicBase {
  YTMusicBase({
    Map<String, dynamic>? auth,
    String? user,
    http.Client? client,
    Map<String, String>? proxies, // placeholder for parity
    String language = 'en',
    String location = '',
  })  : _client = client ?? http.Client(),
        _proxies = proxies {
    _context = initializeContext();
    if (user != null && user.isNotEmpty) {
      _context['context']['user'] = {'onBehalfOfUser': user};
    }
  }

  final http.Client _client;
  final Map<String, String>? _proxies; // ignore: unused_field
  Map<String, dynamic> _context = {};
  final Map<String, String> cookies = {'SOCS': 'CAI'};
  AuthType authType = AuthType.unauthorized;
  late Token _token;
  String? _userAgent;

  Map<String, String> get baseHeaders => initializeHeaders(_userAgent);

  Map<String, String> get headers {
    final headers = Map<String, String>.from(baseHeaders);
    if (authType == AuthType.oauthCustomClient) {
      headers['authorization'] = _token.asAuth();
      headers['X-Goog-Request-Time'] =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    }
    return headers;
  }

  void asMobile() {
    _userAgent = MOBILE_USER_AGENT;
  }

  void asWeb() {
    _userAgent = null;
  }

  Future<Map<String, dynamic>> sendRequest(String endpoint, Map<String, dynamic> body,
      {Map<String, String>? additionalParams}) async {
    final merged = {...body, ..._context};
    Uri uri = Uri.parse('$ytmBaseApi$endpoint$ytmParams');
    if (additionalParams != null) {
      uri = uri.replace(queryParameters: additionalParams);
      
    }

    final response = await _client.post(uri, headers: headers, body: jsonEncode(merged));

    final Map<String, dynamic> responseText = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final message = 'Server returned HTTP ${response.statusCode}: ${response.reasonPhrase}.\n';
      final error = (responseText['error'] as Map?)?.cast<String, dynamic>()['message'];
      throw YTMusicServerError('$message$error');
    }
    return responseText;
  }

  Future<Lyrics?> getLyrics(String browseId, {bool timestamps = false}) async {
    throw UnimplementedError('getLyrics must be implemented by a mixin or subclass.');
  }

  Map<String, String>? parseQueryString(String? queryString) {
    if (queryString == null || queryString.isEmpty) return null;
    final uri = Uri(query: queryString.startsWith('&') ? queryString.substring(1) : queryString);
    return uri.queryParameters.isEmpty ? null : uri.queryParameters;
  }
}


