import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:cinetime/models/api_id.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:fetcher/fetcher_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class TrailerPage extends StatefulWidget {
  const TrailerPage(this.trailerId);

  final ApiId trailerId;

  @override
  State<TrailerPage> createState() => _TrailerPageState();
}

class _TrailerPageState extends State<TrailerPage> {
  /// Whether the back button is visible. Driven by the player, so that it fades with the player controls.
  final _isBackButtonVisible = DataStream(true);

  @override
  void initState() {
    super.initState();

    // Trailers are always played in immersive landscape mode
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _isBackButtonVisible.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Player
          FetchBuilder<VideoData?>(
            task: () => AppService.api.getVideoData(widget.trailerId),
            builder: (context, trailerData) {
              if (trailerData == null) {
                return IconMessage(
                  icon: IconMessage.iconError,
                  message: 'Aucune bande annonce trouvée',
                  redIcon: true,
                  textColor: Colors.white,
                );
              }
              return _VideoPlayerWidget(
                videoData: trailerData,
                isBackButtonVisible: _isBackButtonVisible,
              );
            },
          ),

          // Back button
          Positioned(
            top: 10,
            left: 10,
            child: SafeArea(
              child: DataStreamBuilder<bool>(
                stream: _isBackButtonVisible,
                builder: (context, isVisible) {
                  return IgnorePointer(
                    ignoring: !isVisible,
                    child: AnimatedOpacity(
                      opacity: isVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const BackButton(
                        color: Colors.white,
                        style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.black38)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  const _VideoPlayerWidget({
    required this.videoData,
    required this.isBackButtonVisible,
  });

  final VideoData videoData;
  final DataStream<bool> isBackButtonVisible;

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late final VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  Object? _initError;
  Timer? _hideBackButtonTimer;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.networkUrl(
      widget.videoData.uri,
      httpHeaders: widget.videoData.headers,
    )..addListener(_onPlayerChanged);
    _initialize();
  }

  /// The player is initialized before building the UI, so that the video aspect ratio is known when Chewie is first laid out.
  Future<void> _initialize() async {
    try {
      await _videoPlayerController.initialize();
    } catch (error) {
      if (mounted) setState(() => _initError = error);
      return;
    }
    if (!mounted) return;

    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        showOptions: false,
        // The page is already fullscreen.
        // Chewie's `fullScreenByDefault` (once used to fix the aspect ratio) breaks back navigation, so the ratio is fixed by initializing the player first and passing `aspectRatio`.
        // See https://github.com/fluttercommunity/chewie/issues/647
        allowFullScreen: false,
        autoPlay: true,
        errorBuilder: (_, error) => _buildError(error),
      );
    });
  }

  void _onPlayerChanged() {
    final isPlaying = _videoPlayerController.value.isPlaying;
    if (isPlaying == _wasPlaying) return;
    _wasPlaying = isPlaying;

    WakelockPlus.toggle(enable: isPlaying);
    _showBackButton();
  }

  /// Shows the back button, and hides it after a while if the video is playing (same behavior as Chewie controls).
  void _showBackButton() {
    _hideBackButtonTimer?.cancel();
    widget.isBackButtonVisible.add(true);
    if (_videoPlayerController.value.isPlaying) {
      _hideBackButtonTimer = Timer(ChewieController.defaultHideControlsTimer, () => widget.isBackButtonVisible.add(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) return _buildError(_initError.toString());

    final chewieController = _chewieController;
    if (chewieController == null) {
      return Center(
        child: SpinKitFadingCube(
          color: Theme.of(context).primaryColor,
          size: 25.0,
        ),
      );
    }

    return Listener(
      onPointerDown: (_) => _showBackButton(),
      child: Chewie(
        controller: chewieController,
      ),
    );
  }

  Widget _buildError(String errorMessage) {
    return IconMessage(
      icon: IconMessage.iconError,
      message: 'Impossible de récupérer la bande annonce',
      tooltip: errorMessage,
      redIcon: true,
      textColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _hideBackButtonTimer?.cancel();
    WakelockPlus.disable();
    _chewieController?.dispose();
    _videoPlayerController.dispose();
    super.dispose();
  }
}
