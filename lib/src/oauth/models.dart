/// Models for OAuth authentication (ported from Python TypedDicts)

typedef DefaultScope = String; // constrained to 'https://www.googleapis.com/auth/youtube'
typedef Bearer = String; // constrained to 'Bearer'

class BaseTokenDict {
  BaseTokenDict({
    required this.accessToken,
    required this.expiresIn,
    required this.scope,
    required this.tokenType,
  });

  final String accessToken; // to be used in Authorization header
  final int expiresIn; // seconds until expiration from request timestamp
  final DefaultScope scope; // should be 'https://www.googleapis.com/auth/youtube'
  final Bearer tokenType; // should be 'Bearer'

  factory BaseTokenDict.fromJson(Map<String, dynamic> json) => BaseTokenDict(
        accessToken: json['access_token'] as String,
        expiresIn: (json['expires_in'] as num).toInt(),
        scope: json['scope'] as String,
        tokenType: json['token_type'] as String,
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'expires_in': expiresIn,
        'scope': scope,
        'token_type': tokenType,
      };
}

class RefreshableTokenDict extends BaseTokenDict {
  RefreshableTokenDict({
    required super.accessToken,
    required super.expiresIn,
    required super.scope,
    required super.tokenType,
    required this.expiresAt,
    required this.refreshToken,
  });

  final int expiresAt; // UNIX epoch timestamp in seconds
  final String refreshToken; // used to obtain new access token upon expiration

  factory RefreshableTokenDict.fromJson(Map<String, dynamic> json) =>
      RefreshableTokenDict(
        accessToken: json['access_token'] as String,
        expiresIn: (json['expires_in'] as num).toInt(),
        scope: json['scope'] as String,
        tokenType: json['token_type'] as String,
        expiresAt: (json['expires_at'] as num? ?? 0).toInt(),
        refreshToken: json['refresh_token'] as String,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'expires_at': expiresAt,
        'refresh_token': refreshToken,
      };
}

class AuthCodeDict {
  AuthCodeDict({
    required this.deviceCode,
    required this.userCode,
    required this.expiresIn,
    required this.interval,
    required this.verificationUrl,
  });

  final String deviceCode; // code obtained via user confirmation and oauth consent
  final String userCode; // formatted as XXX-XXX-XXX
  final int expiresIn; // seconds from original request timestamp
  final int interval; // polling interval seconds
  final String verificationUrl; // base url for OAuth consent screen

  factory AuthCodeDict.fromJson(Map<String, dynamic> json) => AuthCodeDict(
        deviceCode: json['device_code'] as String,
        userCode: json['user_code'] as String,
        expiresIn: (json['expires_in'] as num).toInt(),
        interval: (json['interval'] as num).toInt(),
        verificationUrl: json['verification_url'] as String,
      );

  Map<String, dynamic> toJson() => {
        'device_code': deviceCode,
        'user_code': userCode,
        'expires_in': expiresIn,
        'interval': interval,
        'verification_url': verificationUrl,
      };
}


