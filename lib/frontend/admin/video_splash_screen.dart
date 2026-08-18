import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key, required this.destination});

  final Widget destination;

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen>
    with WidgetsBindingObserver {
  late final VideoPlayerController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset(
      'assets/splash-screen.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..addListener(_videoListener);
    _startVideo();
  }

  Future<void> _startVideo() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      await _controller.setVolume(0);
      if (!mounted) return;
      setState(() {});
      await _controller.play();
      if (!_controller.value.isPlaying) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (mounted && !_finished && _controller.value.isInitialized) {
          await _controller.play();
        }
      }
    } catch (_) {
      _finish();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_finished &&
        _controller.value.isInitialized &&
        !_controller.value.isCompleted) {
      _controller.play();
    }
  }

  void _videoListener() {
    if (_controller.value.isCompleted) _finish();
  }

  void _finish() {
    if (!mounted || _finished) return;
    setState(() => _finished = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 350),
    child: _finished
        ? KeyedSubtree(
            key: const ValueKey('admin-app'),
            child: widget.destination,
          )
        : ColoredBox(
            key: const ValueKey('video-splash'),
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_controller.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black38,
                        ),
                        child: const Text('Skip'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
}
