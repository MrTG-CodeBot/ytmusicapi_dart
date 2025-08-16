typedef JsonDict = Map<String, dynamic>;
typedef JsonList = List<dynamic>;

String _getContinuationString(String ctoken) => '&ctoken=$ctoken&continuation=$ctoken';

String? getContinuationParams(JsonDict results, {String ctokenPath = ''}) {
  final conts = results['continuations'] as List?;
  if (conts == null || conts.isEmpty) return null;
  final data = conts.first['next${ctokenPath}ContinuationData']
      ?? conts.first['reloadContinuationData']
      ?? conts.first['nextContinuationData'];
  if (data is Map && data['continuation'] is String) {
    return _getContinuationString(data['continuation'] as String);
  }
  return null;
}

JsonList getContinuationContents(JsonDict continuation) {
  if (continuation.containsKey('contents')) return continuation['contents'] as List;
  if (continuation.containsKey('items')) return continuation['items'] as List;
  return const [];
}

Future<JsonList> getContinuations(
  JsonDict results,
  String continuationType,
  int? limit,
  Future<JsonDict> Function(String additionalParams) requestFunc,
  JsonList Function(JsonList contents) parseFunc,
  {String ctokenPath = ''}
) async {
  final items = <Map<String, dynamic>>[];
  while (results.containsKey('continuations') && (limit == null || items.length < limit)) {
    final additionalParams = getContinuationParams(results, ctokenPath: ctokenPath);
    if (additionalParams == null) break;
    final response = await requestFunc(additionalParams);
    if (response.containsKey('continuationContents')) {
      results = (response['continuationContents'] as Map)[continuationType] as JsonDict;
    } else {
      break;
    }
    final contents = getContinuationContents(results);
    if (contents.isEmpty) break;
    final parsed = parseFunc(contents);
    if (parsed.isEmpty) break;
    items.addAll(parsed.cast<Map<String, dynamic>>());
  }
  return items;
}

Future<JsonList> getReloadableContinuations(
  JsonDict results,
  String continuationType,
  int? limit,
  Future<JsonDict> Function(String additionalParams) requestFunc,
  JsonList Function(JsonList contents) parseFunc,
) async {
  // This mirrors the Python helper for reloadable continuations (special case on playlists suggestions)
  final additionalParams = getContinuationParams(results);
  if (additionalParams == null) return const [];
  return getContinuations(results, continuationType, limit, requestFunc, parseFunc);
}

String? getContinuationToken2025(JsonDict results) {
  final contents = results['contents'] as List?;
  if (contents == null || contents.isEmpty) return null;
  final last = contents.last as Map;
  final token = (((last['continuationItemRenderer'] as Map?)?['continuationEndpoint'] as Map?)?
      ['continuationCommand'] as Map?)?['token'];
  return token as String?;
}

Future<JsonList> getContinuations2025(
  JsonDict results,
  int? limit,
  Future<JsonDict> Function(JsonDict body) requestFuncBody,
  JsonList Function(JsonList contents) parseFunc,
) async {
  final items = <Map<String, dynamic>>[];
  var token = getContinuationToken2025(results);
  while (token != null && (limit == null || items.length < limit)) {
    final response = await requestFuncBody({'continuation': token});
    final continuationItems = ((response['onResponseReceivedActions'] as List?)?.first
            as Map?)?['appendContinuationItemsAction']?['continuationItems'] as List?;
    if (continuationItems == null || continuationItems.isEmpty) break;
    final parsed = parseFunc(continuationItems);
    if (parsed.isEmpty) break;
    items.addAll(parsed.cast<Map<String, dynamic>>());
    // next token
    final nextToken = getContinuationToken2025({'contents': continuationItems});
    if (nextToken == null || nextToken == token) break;
    token = nextToken;
  }
  return items;
}


