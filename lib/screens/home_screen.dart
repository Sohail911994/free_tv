import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../services/iptv_service.dart';
import '../services/storage_service.dart';
import '../widgets/channel_tile.dart';
import 'favorites_screen.dart';
import 'player_screen.dart';
import 'recent_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _iptv = IptvService();
  final _storage = StorageService();
  final _search = TextEditingController();
  List<Channel> _all = [];
  Set<String> _favorites = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _iptv.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final channels = await _iptv.loadChannels(forceRefresh: force);
      final favorites = await _storage.getFavorites();
      if (!mounted) return;
      setState(() {
        _all = channels;
        _favorites = favorites.map((channel) => channel.url).toSet();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _syncFavorites() async {
    final favorites = await _storage.getFavorites();
    if (!mounted) return;
    setState(() => _favorites = favorites.map((channel) => channel.url).toSet());
  }

  Future<void> _open(Channel channel) async {
    await _storage.addRecent(channel);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlayerScreen(channel: channel)),
    );
    await _syncFavorites();
  }

  Future<void> _toggle(Channel channel) async {
    final next = await _storage.toggleFavorite(channel);
    if (!mounted) return;
    setState(() => _favorites = next.map((item) => item.url).toSet());
  }

  List<Channel> get _visible {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _all;
    return _all.where((channel) {
      final haystack = '${channel.name} ${channel.country} ${channel.group}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final channels = _visible;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('Free TV'),
        actions: [
          IconButton(
            tooltip: 'Recent',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RecentScreen()),
              );
              await _syncFavorites();
            },
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Favorites',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
              );
              await _syncFavorites();
            },
            icon: const Icon(Icons.favorite),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _load(force: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search sports channels',
                prefixIcon: Icon(Icons.search, color: Colors.white54),
              ),
            ),
          ),
          Expanded(child: _body(channels)),
        ],
      ),
    );
  }

  Widget _body(List<Channel> channels) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => _load(force: true), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (channels.isEmpty) {
      return const Center(
        child: Text('Koi channel nahi mili', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: channels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final channel = channels[index];
        return ChannelTile(
          channel: channel,
          favorite: _favorites.contains(channel.url),
          onTap: () => _open(channel),
          onFavorite: () => _toggle(channel),
        );
      },
    );
  }
}
