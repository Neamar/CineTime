import 'package:chewie/chewie.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class TrailerPage extends StatefulWidget {
  final String trailerCode;

  const TrailerPage(this.trailerCode);

  @override
  _TrailerPageState createState() => _TrailerPageState();
}

class _TrailerPageState extends State<TrailerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  Object? _error;

  @override
  void initState() {
    fetchTrailerUrl();
    super.initState();
  }

  Future<void> fetchTrailerUrl() async {
    try {
      // Fetch trailer url
      var trailerUrl = await AppService.api.getVideoUrl(widget.trailerCode);

      // Start video player
      setState(() {
        _videoPlayerController = VideoPlayerController.network(trailerUrl!);
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoInitialize: true,
          autoPlay: true,
          errorBuilder: (_, error) => _buildError(error),
        );
      });
    }
    catch (e) {
      setState(() {
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trailer'),
      ),
      backgroundColor: Colors.black,
      body: () {
        // If video is ready
        if (_chewieController != null)
          return Chewie(
            controller: _chewieController!,
          );

        // If an error occurred
        if (_error != null)
          _buildError(_error.toString());

        // If it's still loading
        return Center(
          child: CircularProgressIndicator(),
        );
      } ()
    );
  }

  Widget _buildError(String errorMessage) {
    return IconMessage(
      icon: IconMessage.iconError,
      message: 'Impossible de récuperer la bande annonce',
      tooltip: errorMessage,
      redIcon: true,
      textColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
