import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/channel.dart';
import 'storage_service.dart';

class IptvException implements Exception {
  final String message;
  const IptvException(this.message);

  @override
  String toString() => message;
}

class IptvService {
  static const String m3uUrl = 'https://iptv-org.github.io/iptv/index.m3u';
  static const String streamsUrl = 'https://iptv-org.github.io/api/streams.json';

  static const List<String> _shortKeywords = [
    'f1',
    'nba',
    'nfl',
    'mlb',
    'ufc',
    'wwe',
    'nhl',
    'golf',
  ];

  static const List<String> _nameKeywords = [
    'sport',
    'espn',
    'bein',
    'sky sport',
    'fox sport',
    'supersport',
    'eurosport',
    'dazn',
    'cricket',
    'football',
    'soccer',
    'formula',
    'tennis',
    'ptv sport',
    'geo super',
    'a sport',
    'ten sport',
    'star sport',
    'sony sport',
    'willow',
    'astro sport',
  ];

  final StorageService _storage;
  final http.Client _client;

  IptvService({StorageService? storage, http.Client? client})
      : _storage = storage ?? StorageService(),
        _client = client ?? http.Client();

  Future<List<Channel>> loadChannels({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _readFreshCache();
      if (cached != null) return cached;
    } else {
      await _storage.clearChannelCache();
    }

    try {
      final fresh = await _downloadAndFilter();
      await _storage.cacheChannels(fresh);
      return fresh;
    } catch (error) {
      final stale = await _storage.getCachedChannels();
      if (stale.isNotEmpty) return stale;
      if (error is IptvException) rethrow;
      throw IptvException('Channels download nahi ho saki. Internet check karo.');
    }
  }

  Future<List<Channel>?> _readFreshCache() async {
    if (!await _storage.isCacheValid()) return null;
    final cached = await _storage.getCachedChannels();
    if (cached.isEmpty) return null;
    return cached;
  }

  Future<List<Channel>> _downloadAndFilter() async {
    final m3uResponse = await _get(m3uUrl);
    final sports = parseM3u(m3uResponse);

    Set<String>? online;
    try {
      final streamsBody = await _get(streamsUrl);
      online = onlineUrlSet(jsonDecode(streamsBody));
    } catch (_) {
      online = null;
    }

    final filtered = keepOnline(sports, online);
    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return filtered;
  }

  Future<String> _get(String url) async {
    final response = await _client
        .get(
          Uri.parse(url),
          headers: const {
            'User-Agent': 'Mozilla/5.0 (compatible; FreeTV/1.0)',
            'Accept': '*/*',
          },
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw IptvException('Download fail ($url) — ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  void dispose() {
    _client.close();
  }
}

List<Channel> parseM3u(String body) {
  final channels = <Channel>[];
  final seen = <String>{};
  String? name;
  var logo = '';
  var group = '';
  var country = '';
  var userAgent = '';
  var referrer = '';

  void reset() {
    name = null;
    logo = '';
    group = '';
    country = '';
    userAgent = '';
    referrer = '';
  }

  for (final raw in const LineSplitter().convert(body)) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    if (line.startsWith('#EXTINF')) {
      name = _nameAfterComma(line);
      logo = _attr(line, 'tvg-logo');
      group = _attr(line, 'group-title');
      final declared = _attr(line, 'tvg-country');
      country = declared.isNotEmpty
          ? declared.split(RegExp(r'[;,]')).first.trim().toUpperCase()
          : _countryFromTvgId(_attr(line, 'tvg-id'));
      final ua = _attr(line, 'http-user-agent');
      if (ua.isNotEmpty) userAgent = ua;
      final ref = _attr(line, 'http-referrer').isNotEmpty
          ? _attr(line, 'http-referrer')
          : _attr(line, 'http-referer');
      if (ref.isNotEmpty) referrer = ref;
      continue;
    }

    if (line.startsWith('#EXTVLCOPT:') && name != null) {
      final opt = line.substring('#EXTVLCOPT:'.length);
      final eq = opt.indexOf('=');
      if (eq == -1) continue;
      final key = opt.substring(0, eq).trim().toLowerCase();
      final value = opt.substring(eq + 1).trim();
      if (key == 'http-user-agent' && value.isNotEmpty) userAgent = value;
      if ((key == 'http-referrer' || key == 'http-referer') && value.isNotEmpty) {
        referrer = value;
      }
      continue;
    }

    if (line.startsWith('#') || name == null) continue;
    if (!line.startsWith('http://') && !line.startsWith('https://')) continue;

    final url = line.trim();
    final sports = isSportsChannel(name!, group);
    final channel = Channel(
      name: name!,
      url: url,
      logo: logo,
      group: group,
      country: country,
      userAgent: userAgent,
      referrer: referrer,
    );
    reset();

    if (!sports || seen.contains(url)) continue;
    seen.add(url);
    channels.add(channel);
  }

  return channels;
}

bool isSportsChannel(String name, String group) {
  if (group.toLowerCase().contains('sport')) return true;
  final n = name.toLowerCase();
  for (final keyword in IptvService._shortKeywords) {
    final pattern = RegExp('(?:^|[^a-z0-9])${RegExp.escape(keyword)}(?:[^a-z0-9]|\$)');
    if (pattern.hasMatch(n)) return true;
  }
  for (final keyword in IptvService._nameKeywords) {
    if (n.contains(keyword)) return true;
  }
  return false;
}

Set<String>? onlineUrlSet(dynamic payload) {
  if (payload is! List) return null;

  var usesStatus = false;
  for (final item in payload) {
    if (item is Map && item['status'] != null && item['status'].toString().trim().isNotEmpty) {
      usesStatus = true;
      break;
    }
  }

  final urls = <String>{};
  for (final item in payload) {
    if (item is! Map) continue;
    final url = item['url']?.toString().trim() ?? '';
    if (url.isEmpty) continue;
    if (usesStatus) {
      final status = item['status']?.toString().toLowerCase() ?? '';
      if (status == 'online') urls.add(url);
    } else {
      urls.add(url);
    }
  }
  return urls;
}

List<Channel> keepOnline(List<Channel> channels, Set<String>? online) {
  if (online == null) return channels;
  return channels.where((channel) => online.contains(channel.url.trim())).toList();
}

String _attr(String line, String name) {
  final match = RegExp('$name="([^"]*)"', caseSensitive: false).firstMatch(line);
  return match?.group(1)?.trim() ?? '';
}

String _nameAfterComma(String line) {
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      inQuotes = !inQuotes;
    } else if (char == ',' && !inQuotes) {
      return line.substring(i + 1).trim();
    }
  }
  return '';
}

String _countryFromTvgId(String id) {
  if (id.isEmpty) return '';
  final base = id.split('@').first;
  final dot = base.lastIndexOf('.');
  if (dot == -1 || dot == base.length - 1) return '';
  return base.substring(dot + 1).toUpperCase();
}
