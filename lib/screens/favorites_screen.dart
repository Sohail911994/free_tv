import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../services/storage_service.dart';
import '../widgets/channel_tile.dart';
import 'player_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _storage = StorageService();
  final _search = TextEditingController();
  List<Channel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _storage.getFavorites();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _open(Channel channel) async {
    await _storage.addRecent(channel);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlayerScreen(channel: channel)),
    );
  }

  Future<void> _toggle(Channel channel) async {
    final next = await _storage.toggleFavorite(channel);
    if (!mounted) return;
    setState(() => _items = next);
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final shown = query.isEmpty
        ? _items
        : _items.where((channel) => channel.name.toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(title: const Text('Favorites')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search favorites',
                prefixIcon: Icon(Icons.search, color: Colors.white54),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : shown.isEmpty
                    ? const Center(
                        child: Text(
                          'Heart dabao, channel yahan aayegi',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: shown.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final channel = shown[index];
                          return ChannelTile(
                            channel: channel,
                            favorite: true,
                            onTap: () => _open(channel),
                            onFavorite: () => _toggle(channel),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
