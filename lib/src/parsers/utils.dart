import '../navigation.dart';

typedef JsonDict = Map<String, dynamic>;
typedef JsonList = List<dynamic>;

void parseMenuPlaylists(JsonDict data, JsonDict result) {
  final menuItems = nav<JsonList>(data, MENU_ITEMS, noneIfAbsent: true);
  if (menuItems == null) return;
  final watchMenu = findObjectsByKey(menuItems, MNIR);
  for (final item in watchMenu.map((e) => e[MNIR] as JsonDict)) {
    final icon = nav<String>(item, ICON_TYPE);
    String? watchKey;
    if (icon == 'MUSIC_SHUFFLE') {
      watchKey = 'shuffleId';
    } else if (icon == 'MIX') {
      watchKey = 'radioId';
    } else {
      continue;
    }
    var watchId = nav<String>(item, ['navigationEndpoint', 'watchPlaylistEndpoint', 'playlistId'],
        noneIfAbsent: true);
    watchId ??= nav<String>(item, ['navigationEndpoint', 'watchEndpoint', 'playlistId'],
        noneIfAbsent: true);
    if (watchId != null) result[watchKey] = watchId;
  }
}

String? getItemText(JsonDict item, int index, {int runIndex = 0, bool noneIfAbsent = false}) {
  final column = getFlexColumnItem(item, index);
  if (column == null) return null;
  final runs = nav<List>(column, ['text', 'runs']);
  if (noneIfAbsent && (runs?.length ?? 0) < runIndex + 1) return null;
  return (runs![runIndex] as Map)['text'] as String;
}

JsonDict? getFlexColumnItem(JsonDict item, int index) {
  final columns = item['flexColumns'] as List?;
  if (columns == null || columns.length <= index) return null;
  final renderer = (columns[index] as Map)['musicResponsiveListItemFlexColumnRenderer'] as Map?;
  if (renderer == null) return null;
  if (!(renderer.containsKey('text') && (renderer['text'] as Map).containsKey('runs'))) return null;
  return renderer.cast<String, dynamic>();
}

JsonDict? getFixedColumnItem(JsonDict item, int index) {
  final columns = item['fixedColumns'] as List?;
  if (columns == null || columns.length <= index) return null;
  final renderer = (columns[index] as Map)['musicResponsiveListItemFixedColumnRenderer'] as Map?;
  if (renderer == null) return null;
  if (!(renderer.containsKey('text') && (renderer['text'] as Map).containsKey('runs'))) return null;
  return renderer.cast<String, dynamic>();
}

int getDotSeparatorIndex(JsonList runs) {
  final idx = runs.indexWhere((e) => e is Map && e['text'] == ' • ');
  return idx == -1 ? runs.length : idx;
}

int? parseDuration(String? duration) {
  if (duration == null || duration.trim().isEmpty) return null;
  final parts = duration.trim().split(':');
  if (parts.any((p) => int.tryParse(p) == null)) return null;
  var seconds = 0;
  var multiplier = 1;
  for (final part in parts.reversed) {
    seconds += int.parse(part) * multiplier;
    multiplier *= 60;
  }
  return seconds;
}

Map<String, dynamic> parseIdName(JsonDict? subRun) {
  return {
    'id': nav<String>(subRun, NAVIGATION_BROWSE_ID, noneIfAbsent: true),
    'name': nav<String>(subRun, ['text'], noneIfAbsent: true),
  };
}


