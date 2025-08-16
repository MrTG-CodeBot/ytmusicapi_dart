class LyricLine {
  final String text;
  final int startTime;
  final int endTime;
  final int id;

  LyricLine({
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.id,
  });

  factory LyricLine.fromJson(Map<String, dynamic> json) {
    return LyricLine(
      text: json['text'] as String,
      startTime: json['start_time'] as int,
      endTime: json['end_time'] as int,
      id: json['id'] as int,
    );
  }

  get time => null;
}

class Timestamp {
  final String start;
  final String end;
  final String line;

  Timestamp({
    required this.start,
    required this.end,
    required this.line,
  });

  factory Timestamp.fromJson(Map<String, dynamic> json) {
    return Timestamp(
      start: json['start'] as String,
      end: json['end'] as String,
      line: json['line'] as String,
    );
  }
}

class Lyrics {
  final String lyrics;
  final String? title;
  final String? artist;
  final String? source;
  final bool hasTimestamps;
  final List<Timestamp>? timestamps;

  Lyrics({
    required this.lyrics,
    this.title,
    this.artist,
    this.source,
    required this.hasTimestamps,
    this.timestamps,
  });
}

class TimedLyrics extends Lyrics {
  final List<LyricLine> lines;

  TimedLyrics({
    required this.lines,
    String? title,
    String? artist,
    String? source,
    required bool hasTimestamps,
    List<Timestamp>? timestamps,
  }) : super(
          lyrics: lines.map((e) => e.text).join('\n'),
          title: title,
          artist: artist,
          source: source,
          hasTimestamps: hasTimestamps,
          timestamps: timestamps,
        );
}