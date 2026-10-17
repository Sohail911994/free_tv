import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/channel.dart';

class StorageService {
  static const String channelsKey = 'cached_channels';
  static const String lastUpdateKey = 'last_update';
  static const String favoritesKey = 'favorites';
  static const String recentKey = 'recent';
  static const int maxRecent = 20;
  static const Duration cacheDuration = Duration(hours: 24);

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> isCacheValid() async {
    final prefs = await _prefs;
    final stamp = prefs.getInt(lastUpdateKey);
    if (stamp == null) return false;
    final savedAt = DateTime.fromMillisecondsSinceEpoch(stamp);
    return DateTime.now().difference(savedAt) < cacheDuration;
  }

  Future<List<Channel>> getCachedChannels() async {
    final prefs = await _prefs;
    return _decode(prefs.getString(channelsKey));
  }

  Future<void> cacheChannels(List<Channel> channels) async {
    final prefs = await _prefs;
    await prefs.setString(channelsKey, jsonEncode(channels.map((c) => c.toJson()).toList()));
    await prefs.setInt(lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> clearChannelCache() async {
    final prefs = await _prefs;
    await prefs.remove(channelsKey);
    await prefs.remove(lastUpdateKey);
  }

  Future<List<Channel>> getFavorites() async {
    final prefs = await _prefs;
    return _decode(prefs.getString(favoritesKey));
  }

  Future<bool> isFavorite(String url) async {
    final favorites = await getFavorites();
    return favorites.any((channel) => channel.url == url);
  }

  Future<List<Channel>> toggleFavorite(Channel channel) async {
    final prefs = await _prefs;
    final favorites = _decode(prefs.getString(favoritesKey));
    final exists = favorites.any((item) => item.url == channel.url);
    final next = exists
        ? favorites.where((item) => item.url != channel.url).toList()
        : [channel, ...favorites];
    await prefs.setString(favoritesKey, jsonEncode(next.map((c) => c.toJson()).toList()));
    return next;
  }

  Future<List<Channel>> getRecent() async {
    final prefs = await _prefs;
    return _decode(prefs.getString(recentKey));
  }

  Future<List<Channel>> addRecent(Channel channel) async {
    final prefs = await _prefs;
    final recent = _decode(prefs.getString(recentKey));
    final next = [
      channel,
      ...recent.where((item) => item.url != channel.url),
    ].take(maxRecent).toList();
    await prefs.setString(recentKey, jsonEncode(next.map((c) => c.toJson()).toList()));
    return next;
  }

  List<Channel> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final channels = <Channel>[];
      for (final item in decoded) {
        if (item is Map) {
          final channel = Channel.fromJson(Map<String, dynamic>.from(item));
          if (channel.url.isNotEmpty && channel.name.isNotEmpty) {
            channels.add(channel);
          }
        }
      }
      return channels;
    } catch (_) {
      return [];
    }
  }
}
