import 'dart:convert';
import 'dart:io';

import 'credentials.dart';
import 'models.dart';

class Token {
  Token({
    required this.scope,
    required this.tokenType,
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt = 0,
    this.expiresIn = 0,
  });

  final DefaultScope scope;
  final Bearer tokenType;
  String accessToken;
  final String refreshToken;
  int expiresAt;
  int expiresIn;

  Map<String, dynamic> asMap() => {
        'scope': scope,
        'token_type': tokenType,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt,
        'expires_in': expiresIn,
      };

  String asJson() => jsonEncode(asMap());

  String asAuth() => '$tokenType $accessToken';

  bool get isExpiring => expiresIn < 60;

  @override
  String toString() => 'Token: ${asMap()}';
}

class OAuthToken extends Token {
  OAuthToken({
    required super.scope,
    required super.tokenType,
    required super.accessToken,
    required super.refreshToken,
    super.expiresAt,
    super.expiresIn,
  });

  void update(BaseTokenDict freshAccess) {
    accessToken = freshAccess.accessToken;
    expiresAt = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + freshAccess.expiresIn;
  }

  bool get isExpiring => (expiresAt - (DateTime.now().millisecondsSinceEpoch ~/ 1000)) < 60;

  static OAuthToken fromJsonFile(File file) {
    final content = file.readAsStringSync();
    final map = json.decode(content) as Map<String, dynamic>;
    return OAuthToken(
      scope: map['scope'] as String,
      tokenType: map['token_type'] as String,
      accessToken: map['access_token'] as String,
      refreshToken: map['refresh_token'] as String,
      expiresAt: (map['expires_at'] as num? ?? 0).toInt(),
      expiresIn: (map['expires_in'] as num? ?? 0).toInt(),
    );
  }
}

class RefreshingToken extends OAuthToken {
  RefreshingToken({
    required this.credentials,
    File? localCache,
    required super.scope,
    required super.tokenType,
    required super.accessToken,
    required super.refreshToken,
    super.expiresAt,
    super.expiresIn,
  }) : _localCache = localCache;

  final Credentials credentials;
  File? _localCache;

  File? get localCache => _localCache;
  set localCache(File? file) {
    _localCache = file;
    storeToken();
  }

  String get accessTokenAutoRefresh {
    if (isExpiring) {
      // refresh
      // ignore: discarded_futures
      credentials.refreshToken(refreshToken).then((fresh) {
        update(fresh);
        storeToken();
      });
    }
    return accessToken;
  }

  static Future<RefreshingToken> promptForToken({
    required OAuthCredentials credentials,
    bool openBrowser = false,
    String? toFile,
  }) async {
    final code = await credentials.getCode();
    // final url = '${code.verificationUrl}?user_code=${code.userCode}';
    if (openBrowser) {
      // No cross-platform browser open in pure Dart core; defer to user.
    }
    // In Dart CLI, we cannot block for input synchronously inside library code.
    // Consumers should handle prompting and pass the device code to tokenFromCode.
    final rawToken = await credentials.tokenFromCode(code.deviceCode);
    final refToken = RefreshingToken(
      credentials: credentials,
      scope: rawToken.scope,
      tokenType: rawToken.tokenType,
      accessToken: rawToken.accessToken,
      refreshToken: rawToken.refreshToken,
      expiresAt: rawToken.expiresAt,
      expiresIn: rawToken.expiresIn,
      localCache: toFile != null ? File(toFile) : null,
    );
    refToken.update(rawToken);
    if (toFile != null) {
      refToken.localCache = File(toFile);
    }
    return refToken;
  }

  void storeToken({String? path}) {
    final file = path != null ? File(path) : _localCache;
    if (file != null) {
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(asMap()));
    }
  }
}


