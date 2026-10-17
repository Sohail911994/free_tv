import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/channel.dart';

class ChannelTile extends StatelessWidget {
  final Channel channel;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const ChannelTile({
    super.key,
    required this.channel,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [channel.country, channel.group].where((part) => part.isNotEmpty).join(' · ');
    return Material(
      color: const Color(0xFF1C1C2E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              _Logo(channel: channel),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta.isEmpty ? 'Sports' : meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavorite,
                icon: Icon(
                  favorite ? Icons.favorite : Icons.favorite_border,
                  color: favorite ? Colors.tealAccent : Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final Channel channel;
  const _Logo({required this.channel});

  @override
  Widget build(BuildContext context) {
    if (channel.logo.isEmpty) return _fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: channel.logo,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        placeholder: (_, __) => _fallback(),
        errorWidget: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    final trimmed = channel.name.trim();
    final letter = trimmed.isEmpty ? 'TV' : trimmed[0].toUpperCase();
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(letter, style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.w700)),
    );
  }
}
