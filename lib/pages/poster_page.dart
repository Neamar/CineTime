import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class PosterPage extends StatelessWidget {
  const PosterPage(this.posterPath);

  final String posterPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(ApiClient.getImageUrl(posterPath, isThumbnail: false)!),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.contained * 1.5,
      ),
    );
  }
}
