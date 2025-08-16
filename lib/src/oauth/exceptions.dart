class UnauthorizedOAuthClient implements Exception {
  UnauthorizedOAuthClient(this.message);
  final String message;
  @override
  String toString() => 'UnauthorizedOAuthClient: $message';
}

class BadOAuthClient implements Exception {
  BadOAuthClient(this.message);
  final String message;
  @override
  String toString() => 'BadOAuthClient: $message';
}


