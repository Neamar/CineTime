import 'package:chewie/chewie.dart';
import 'package:cinetime/models/api_id.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/utils/_utils.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class TrailerPage extends StatelessWidget {
  const TrailerPage(this.trailerId);

  final ApiId trailerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trailer'),
      ),
      backgroundColor: Colors.black,
      body: FetchBuilder.simple<String>(
        task: () => AppService.api.getVideoUrl(trailerId),
        builder: (context, trailerUrl) {
          return _VideoPlayerWidget(
            videoUrl: trailerUrl,
          );
        },
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  const _VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  final String videoUrl;

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoInitialize: true,
      autoPlay: true,
      errorBuilder: (_, error) => _buildError(error),
    );
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
