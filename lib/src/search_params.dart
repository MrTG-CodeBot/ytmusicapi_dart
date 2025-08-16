String? getSearchParams(String? filter, String? scope, bool ignoreSpelling) {
  const filteredParam1 = 'EgWKAQ';
  String? params;
  String? param1;
  String? param2;
  String? param3;

  if (filter == null && scope == null && !ignoreSpelling) return params;

  if (scope == 'uploads') {
    params = 'agIYAw%3D%3D';
  }

  if (scope == 'library') {
    if (filter != null) {
      param1 = filteredParam1;
      param2 = _getParam2(filter);
      param3 = 'AWoKEAUQCRADEAoYBA%3D%3D';
    } else {
      params = 'agIYBA%3D%3D';
    }
  }

  if (scope == null && filter != null) {
    if (filter == 'playlists') {
      params = 'Eg-KAQwIABAAGAAgACgB';
      if (!ignoreSpelling) {
        params += 'MABqChAEEAMQCRAFEAo%3D';
      } else {
        params += 'MABCAggBagoQBBADEAkQBRAK';
      }
    } else if (filter.contains('playlists')) {
      param1 = 'EgeKAQQoA';
      if (filter == 'featured_playlists') {
        param2 = 'Dg';
      } else {
        param2 = 'EA';
      }
      if (!ignoreSpelling) {
        param3 = 'BagwQDhAKEAMQBBAJEAU%3D';
      } else {
        param3 = 'BQgIIAWoMEA4QChADEAQQCRAF';
      }
    } else {
      param1 = filteredParam1;
      param2 = _getParam2(filter);
      if (!ignoreSpelling) {
        param3 = 'AWoMEA4QChADEAQQCRAF';
      } else {
        param3 = 'AUICCAFqDBAOEAoQAxAEEAkQBQ%3D%3D';
      }
    }
  }

  if (scope == null && filter == null && ignoreSpelling) {
    params = 'EhGKAQ4IARABGAEgASgAOAFAAUICCAE%3D';
  }

  return params ?? '${param1!}${param2!}${param3!}';
}

String _getParam2(String filter) {
  const filterParams = {
    'songs': 'II',
    'videos': 'IQ',
    'albums': 'IY',
    'artists': 'Ig',
    'playlists': 'Io',
    'profiles': 'JY',
    'podcasts': 'JQ',
    'episodes': 'JI',
  };
  return filterParams[filter]!;
}


