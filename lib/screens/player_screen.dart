import 'package:better_player_plus/better_player_plus.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _setupPlayer();
  }

  Map<String, String>? _headers() {
    final headers = <String, String>{};

    if (widget.channel.userAgent.isNotEmpty) {
      headers['User-Agent'] = widget.channel.userAgent;
    }
    if (widget.channel.referrer.isNotEmpty) {
      headers['Referer'] = widget.channel.referrer;
    }

    return headers.isEmpty ? null : headers;
  }

  Future<void> _setupPlayer() async {
    final headers = _headers();

    final source = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.channel.url,
      liveStream: true,
      headers: headers,
      // use this if your stream is HLS/M3U8:
      // videoFormat: VideoFormat.hls,
    );

    final config = BetterPlayerConfiguration(
      autoPlay: true,
      aspectRatio: 16 / 9,
      fit: BoxFit.contain,
      handleLifecycle: true,
      allowedScreenSleep: false,
      looping: false,
      controlsConfiguration: const BetterPlayerControlsConfiguration(
        enableSkips: false,
        enablePlaybackSpeed: false,
        enableFullscreen: true,
        enableMute: true,
        enableQualities: false,
      ),
    );

    final controller = BetterPlayerController(
      config,
      betterPlayerDataSource: source,
    );

    controller.addEventsListener((event) {
      if (!mounted) return;

      if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }

      if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
        setState(() {
          _failed = false;
          _loading = false;
        });
      }
    });

    setState(() {
      _controller = controller;
      _loading = false;
    });
  }

  void _retry() {
    if (_controller != null) {
      _controller!.dispose();
    }

    setState(() {
      _failed = false;
      _loading = true;
    });

    _setupPlayer();
  }

  @override
  void dispose() {
    _controller?.removeEventsListener((event) {});
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: Text(
          widget.channel.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Colors.black,
              child: controller == null
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.tealAccent),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        BetterPlayer(controller: controller),
                        if (_loading)
                          const Positioned.fill(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.tealAccent,
                              ),
                            ),
                          ),
                        if (_failed)
                          ColoredBox(
                            color: const Color(0xCC0F0F1E),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Stream start nahi hui',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Link dead ho sakti hai ya network block ho sakti hai.',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
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
