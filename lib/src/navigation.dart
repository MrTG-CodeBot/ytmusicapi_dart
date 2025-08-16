// Navigation helpers and path constants ported from Python navigation.py

typedef JsonDict = Map<String, dynamic>;
typedef JsonList = List<dynamic>;

// Paths
const CONTENT = ['contents', 0];

const RUN_TEXT = ['runText'];
const TAB_CONTENT = ['tabs', 0, 'tabRenderer', 'content'];
const TAB_1_CONTENT = ['tabs', 1, 'tabRenderer', 'content'];
const TAB_2_CONTENT = ['tabs', 2, 'tabRenderer', 'content'];
const TWO_COLUMN_RENDERER = ['contents', 'twoColumnBrowseResultsRenderer'];
const SINGLE_COLUMN = ['contents', 'singleColumnBrowseResultsRenderer'];
final SINGLE_COLUMN_TAB = [...SINGLE_COLUMN, ...TAB_CONTENT];
const SECTION = ['sectionListRenderer'];
final SECTION_LIST = [...SECTION, 'contents'];
final SECTION_LIST_ITEM = [...SECTION, ...CONTENT];
const RESPONSIVE_HEADER = ['musicResponsiveHeaderRenderer'];
final ITEM_SECTION = ['itemSectionRenderer', ...CONTENT];
const MUSIC_SHELF = ['musicShelfRenderer'];
const GRID = ['gridRenderer'];
final GRID_ITEMS = [...GRID, 'items'];
const MENU = ['menu', 'menuRenderer'];
final MENU_ITEMS = [...MENU, 'items'];
final MENU_LIKE_STATUS = [...MENU, 'topLevelButtons', 0, 'likeButtonRenderer', 'likeStatus'];
const MENU_SERVICE = ['menuServiceItemRenderer', 'serviceEndpoint'];
const TOGGLE_MENU = 'toggleMenuServiceItemRenderer';
final OVERLAY_RENDERER = ['musicItemThumbnailOverlayRenderer', 'content', 'musicPlayButtonRenderer'];
final PLAY_BUTTON = ['overlay', ...OVERLAY_RENDERER];
const NAVIGATION_BROWSE = ['navigationEndpoint', 'browseEndpoint'];
final NAVIGATION_BROWSE_ID = [...NAVIGATION_BROWSE, 'browseId'];
final PAGE_TYPE = ['browseEndpointContextSupportedConfigs', 'browseEndpointContextMusicConfig', 'pageType'];
const WATCH_VIDEO_ID = ['watchEndpoint', 'videoId'];
const PLAYLIST_ID = ['playlistId'];
final WATCH_PLAYLIST_ID = ['watchEndpoint', ...PLAYLIST_ID];
final NAVIGATION_VIDEO_ID = ['navigationEndpoint', ...WATCH_VIDEO_ID];
const QUEUE_VIDEO_ID = ['queueAddEndpoint', 'queueTarget', 'videoId'];
final NAVIGATION_PLAYLIST_ID = ['navigationEndpoint', ...WATCH_PLAYLIST_ID];
final WATCH_PID = ['watchPlaylistEndpoint', ...PLAYLIST_ID];
final NAVIGATION_WATCH_PLAYLIST_ID = ['navigationEndpoint', ...WATCH_PID];
final NAVIGATION_VIDEO_TYPE = [
  'watchEndpoint',
  'watchEndpointMusicSupportedConfigs',
  'watchEndpointMusicConfig',
  'musicVideoType',
];
const ICON_TYPE = ['icon', 'iconType'];
const TOGGLED_BUTTON = ['toggleButtonRenderer', 'isToggled'];
const TITLE = ['title', 'runs', 0];
final TITLE_TEXT = ['title', ...RUN_TEXT];
const TEXT_RUNS = ['text', 'runs'];
final TEXT_RUN = [...TEXT_RUNS, 0];
final TEXT_RUN_TEXT = [...TEXT_RUN, 'text'];
final SUBTITLE = ['subtitle', ...RUN_TEXT];
const SUBTITLE_RUNS = ['subtitle', 'runs'];
final SUBTITLE_RUN = [...SUBTITLE_RUNS, 0];
final SUBTITLE2 = [...SUBTITLE_RUNS, 2, 'text'];
final SUBTITLE3 = [...SUBTITLE_RUNS, 4, 'text'];
const THUMBNAIL = ['thumbnail', 'thumbnails'];
final THUMBNAILS = ['thumbnail', 'musicThumbnailRenderer', ...THUMBNAIL];
final THUMBNAIL_RENDERER = ['thumbnailRenderer', 'musicThumbnailRenderer', ...THUMBNAIL];
final THUMBNAIL_OVERLAY_NAVIGATION = ['thumbnailOverlay', ...OVERLAY_RENDERER, 'playNavigationEndpoint'];
final THUMBNAIL_OVERLAY = [...THUMBNAIL_OVERLAY_NAVIGATION, ...WATCH_PID];
final THUMBNAIL_CROPPED = ['thumbnail', 'croppedSquareThumbnailRenderer', ...THUMBNAIL];
final FEEDBACK_TOKEN = ['feedbackEndpoint', 'feedbackToken'];
final BADGE_PATH = [0, 'musicInlineBadgeRenderer', 'accessibilityData', 'accessibilityData', 'label'];
final BADGE_LABEL = ['badges', ...BADGE_PATH];
final SUBTITLE_BADGE_LABEL = ['subtitleBadges', ...BADGE_PATH];
final CATEGORY_TITLE = ['musicNavigationButtonRenderer', 'buttonText', ...RUN_TEXT];
final CATEGORY_PARAMS = ['musicNavigationButtonRenderer', 'clickCommand', 'browseEndpoint', 'params'];
const MMRIR = 'musicMultiRowListItemRenderer';
const MRLIR = 'musicResponsiveListItemRenderer';
const MTRIR = 'musicTwoRowItemRenderer';
const MNIR = 'menuNavigationItemRenderer';
final TASTE_PROFILE_ITEMS = ['contents', 'tastebuilderRenderer', 'contents'];
const TASTE_PROFILE_ARTIST = ['title', 'runs'];
final SECTION_LIST_CONTINUATION = ['continuationContents', 'sectionListContinuation'];
final MENU_PLAYLIST_ID = [...MENU_ITEMS, 0, MNIR, ...NAVIGATION_WATCH_PLAYLIST_ID];
const MULTI_SELECT = ['musicMultiSelectMenuItemRenderer'];
const HEADER = ['header'];
final HEADER_DETAIL = [...HEADER, 'musicDetailHeaderRenderer'];
const EDITABLE_PLAYLIST_DETAIL_HEADER = ['musicEditablePlaylistDetailHeaderRenderer'];
final HEADER_EDITABLE_DETAIL = [...HEADER, ...EDITABLE_PLAYLIST_DETAIL_HEADER];
final HEADER_SIDE = [...HEADER, 'musicSideAlignedItemRenderer'];
final HEADER_MUSIC_VISUAL = [...HEADER, 'musicVisualHeaderRenderer'];
const DESCRIPTION_SHELF = ['musicDescriptionShelfRenderer'];
const DESCRIPTION = ['description'];
const CAROUSEL = ['musicCarouselShelfRenderer'];
const IMMERSIVE_CAROUSEL = ['musicImmersiveCarouselShelfRenderer'];
final CAROUSEL_CONTENTS = [...CAROUSEL, 'contents'];
final CAROUSEL_TITLE = [...HEADER, 'musicCarouselShelfBasicHeaderRenderer', ...TITLE];
final CARD_SHELF_TITLE = [...HEADER, 'musicCardShelfHeaderBasicRenderer', ...TITLE_TEXT];
final FRAMEWORK_MUTATIONS = ['frameworkUpdates', 'entityBatchUpdate', 'mutations'];
final TIMESTAMPED_LYRICS = [
  'contents',
  'elementRenderer',
  'newElement',
  'type',
  'componentType',
  'model',
  'timedLyricsModel',
  'lyricsData',
];

T? nav<T>(dynamic root, List<dynamic> items, {bool noneIfAbsent = false}) {
  try {
    var current = root;
    for (final k in items) {
      if (current is Map<String, dynamic> && k is String) {
        current = current[k];
      } else if (current is List && k is int) {
        current = current[k];
      } else {
        if (noneIfAbsent) return null;
        throw StateError("Invalid path segment $k for $current");
      }
    }
    return current as T?;
  } catch (e) {
    if (noneIfAbsent) return null;
    rethrow;
  }
}

JsonDict? findObjectByKey(List list, String key, {String? nested, bool isKey = false}) {
  for (final element in list) {
    var item = element;
    if (nested != null && item is Map && item.containsKey(nested)) {
      item = item[nested];
    }
    if (item is Map && item.containsKey(key)) {
      return isKey ? (item[key] as JsonDict?) : (item as JsonDict);
    }
  }
  return null;
}

List<JsonDict> findObjectsByKey(List list, String key, {String? nested}) {
  final objects = <JsonDict>[];
  for (final element in list) {
    var item = element;
    if (nested != null && item is Map && item.containsKey(nested)) {
      item = item[nested];
    }
    if (item is Map && item.containsKey(key)) {
      objects.add(item as JsonDict);
    }
  }
  return objects;
}


