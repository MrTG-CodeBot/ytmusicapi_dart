import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../exceptions.dart';
import 'exceptions.dart' show UnauthorizedOAuthClient, BadOAuthClient;
import 'models.dart';

abstract class Credentials {
  Credentials({required this.clientId, required this.clientSecret, http.Client? client})
      : _client = client ?? http.Client();

  final String clientId;
  final String clientSecret;
  final http.Client _client;

  Future<AuthCodeDict> getCode();
  Future<RefreshableTokenDict> tokenFromCode(String deviceCode);
  Future<BaseTokenDict> refreshToken(String refreshToken);
}

class OAuthCredentials extends Credentials {
  OAuthCredentials({
    required super.clientId,
    required super.clientSecret,
    http.Client? client,
  }) : super(client: client);

  Future<http.Response> _sendRequest(Uri url, Map<String, String> data) async {
    final body = {
      ...data,
      'client_id': clientId,
    };
    final response = await _client.post(
      url,
      headers: {'User-Agent': oauthUserAgent},
      body: body,
    );
    if (response.statusCode == 401) {
      final Map<String, dynamic> content = json.decode(response.body) as Map<String, dynamic>;
      final issue = content['error'];
      if (issue == 'unauthorized_client') {
        throw UnauthorizedOAuthClient('Token refresh error. Most likely client/token mismatch.');
      } else if (issue == 'invalid_client') {
        throw BadOAuthClient(
            'OAuth client failure. Most likely client_id and client_secret mismatch or YouTubeData API is not enabled.');
      } else {
        throw YTMusicServerError(
            'OAuth request error. status_code: ${response.statusCode}, url: $url, content: $content');
      }
    }
    return response;
  }

  @override
  Future<AuthCodeDict> getCode() async {
    final response = await _sendRequest(Uri.parse(oauthCodeUrl), {'scope': oauthScope});
    final jsonMap = json.decode(response.body) as Map<String, dynamic>;
    return AuthCodeDict.fromJson(jsonMap);
  }

  @override
  Future<RefreshableTokenDict> tokenFromCode(String deviceCode) async {
    final response = await _sendRequest(Uri.parse(oauthTokenUrl), {
      'client_secret': clientSecret,
      'grant_type': 'http://oauth.net/grant_type/device/1.0',
      'code': deviceCode,
    });
    final jsonMap = json.decode(response.body) as Map<String, dynamic>;
    return RefreshableTokenDict.fromJson(jsonMap);
  }

  @override
  Future<BaseTokenDict> refreshToken(String refreshTokenValue) async {
    final response = await _sendRequest(Uri.parse(oauthTokenUrl), {
      'client_secret': clientSecret,
      'grant_type': 'refresh_token',
      'refresh_token': refreshTokenValue,
    });
    final jsonMap = json.decode(response.body) as Map<String, dynamic>;
    return BaseTokenDict.fromJson(jsonMap);
  }
}


