class YTMusicError implements Exception {
  YTMusicError([this.message]);
  final String? message;
  @override
  String toString() => 'YTMusicError${message != null ? ': $message' : ''}';
}

class YTMusicUserError extends YTMusicError {
  YTMusicUserError([super.message]);
}

class YTMusicServerError extends YTMusicError {
  YTMusicServerError([super.message]);
}


