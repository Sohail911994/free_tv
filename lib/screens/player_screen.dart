import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';

import '../models/channel.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  BetterPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Map<String, String>? _headers() {
    final headers = <String, String>{};
    if (widget.channel.userAgent.isNotEmpty) {
      headers['User-Agent'] = widget.channel.userAgent;
    }
    if (widget.channel.referrer.isNotEmpty) {
      headers['Referer'] = widget.channel.referrer;
    }
    if (headers.isEmpty) return null;
    return headers;
  }

  void _setup() {
    final source = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.channel.url,
      liveStream: true,
      headers: _headers(),
    );
    final controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        handleLifecycle: true,
        allowedScreenSleep: false,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableSkips: false,
          enablePlaybackSpeed: false,
          enableFullscreen: true,
        ),
      ),
      betterPlayerDataSource: source,
    );
    controller.addEventsListener((event) {
      if (event.betterPlayerEventType == BetterPlayerEventType.exception && mounted) {
        setState(() => _failed = true);
      }
    });
    setState(() => _controller = controller);
  }

  void _retry() {
    _controller?.dispose();
    setState(() => _failed = false);
    _setup();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: Text(widget.channel.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Colors.black,
              child: controller == null
                  ? const SizedBox.shrink()
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        BetterPlayer(controller: controller),
                        if (_failed)
                          ColoredBox(
                            color: const Color(0xCC0F0F1E),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Stream start nahi hui',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Link band ho sakti hai, ya is mulk mein block hai.',
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: _retry,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.channel.country.isEmpty ? 'Live' : widget.channel.country,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
