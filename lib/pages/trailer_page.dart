import 'package:cinetime/models/api_id.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:cinetime/widgets/_widgets.dart';
import 'package:fetcher/fetcher_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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
        child: FetchBuilder<Uri?>(
          task: () => AppService.api.getVideoUri(trailerId),
          builder: (context, trailerUri) {
            if (trailerUri == null) {
              return IconMessage(
                icon: IconMessage.iconError,
                message: 'Aucune bande annonce trouvée',
                redIcon: true,
                textColor: Colors.white,
              );
            }
            return _VideoPlayerWidget(
              videoUri: trailerUri,
            );
          },
        ),
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  const _VideoPlayerWidget({required this.videoUri});

  final Uri videoUri;

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late final Player _player = Player();
  // Note: media_kit has two known limitations:
  // 1. +15MB AAB size due to bundled FFmpeg native libs (unavoidable, inherent to media_kit)
  // 2. Video rendering does not work on Android emulators (native texture surface not supported)
  late final VideoController _controller = VideoController(_player, configuration: const VideoControllerConfiguration(
    enableHardwareAcceleration: !kDebugMode,    // TODO this doesn't help
  ));
  final _videoKey = GlobalKey<VideoState>();

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();
    _player.open(Media(widget.videoUri.toString()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _videoKey.currentState?.enterFullscreen());
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      key: _videoKey,
      controller: _controller,
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
