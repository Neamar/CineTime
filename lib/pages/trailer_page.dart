import 'package:chewie/chewie.dart';
import 'package:cinetime/models/api_id.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:fetcher/fetcher_bloc.dart';

class TrailerPage extends StatelessWidget {
  const TrailerPage(this.trailerId);

  final ApiId trailerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trailer'),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: FetchBuilder<VideoData?>(
          task: () => AppService.api.getVideoData(trailerId),
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
            );
          },
        ),
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  const _VideoPlayerWidget({required this.videoData});

  final VideoData videoData;

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  bool isInit = true;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.networkUrl(
      widget.videoData.uri,
      httpHeaders: widget.videoData.headers,
    );
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      showOptions: false,
      autoInitialize: true,
      autoPlay: true,
      fullScreenByDefault: true,    // We force fullscreen mode because otherwise video has a invalid aspect ratio
      errorBuilder: (_, error) => _buildError(error),
    );

    // Hack to properly handle full screen mode & back navigation
    // See https://github.com/fluttercommunity/chewie/issues/647
    _chewieController.addListener(() {
      final isFullScreen = _chewieController.isFullScreen;
      if (isFullScreen && isInit) {
        _chewieController.exitFullScreen();
        setState(() {
          isInit = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Chewie(
      controller: _chewieController,
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
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }
}
