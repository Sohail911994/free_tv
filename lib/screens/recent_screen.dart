import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../services/storage_service.dart';
import '../widgets/channel_tile.dart';
import 'player_screen.dart';

class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  final _storage = StorageService();
  List<Channel> _items = [];
  Set<String> _favorites = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _storage.getRecent();
    final favorites = await _storage.getFavorites();
    if (!mounted) return;
    setState(() {
      _items = items;
      _favorites = favorites.map((channel) => channel.url).toSet();
      _loading = false;
    });
  }

  Future<void> _open(Channel channel) async {
    await _storage.addRecent(channel);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlayerScreen(channel: channel)),
    );
    await _load();
  }

  Future<void> _toggle(Channel channel) async {
    final next = await _storage.toggleFavorite(channel);
    if (!mounted) return;
    setState(() => _favorites = next.map((item) => item.url).toSet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text('Recent')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'Jo channel chalao ge, woh yahan aayegi',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final channel = _items[index];
                    return ChannelTile(
                      channel: channel,
                      favorite: _favorites.contains(channel.url),
                      onTap: () => _open(channel),
                      onFavorite: () => _toggle(channel),
                    );
                  },
                ),
    );
  }
}
