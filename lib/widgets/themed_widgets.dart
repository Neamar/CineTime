import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/app_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CtProgressIndicator extends StatelessWidget {
  const CtProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitCubeGrid(
        color: Theme.of(context).primaryColor,
      )
    );
  }
}

class CtCachedImage extends StatelessWidget {
  const CtCachedImage({
    super.key,
    this.path,
    this.isThumbnail = false,
    this.dimmed = false,
    this.placeHolderBackground = false,
    this.onPressed,
  });

  final String? path;
  final bool isThumbnail;
  final bool dimmed;
  final bool placeHolderBackground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const errorWidget = Center(
      child: Icon(Icons.image),
    );

    if (path?.isNotEmpty != true)
      return errorWidget;

    return CachedNetworkImage(
      imageUrl: AppService.api.getImageUrl(path, isThumbnail: isThumbnail)!,
      imageBuilder: (_, image) => GestureDetector(
        onTap: onPressed,
        child: Image(
          image: image,
          fit: BoxFit.cover,
          color: dimmed ? Colors.black.withValues(alpha: 0.3) : null,
          colorBlendMode: BlendMode.srcATop,
        ),
      ),
      placeholder: (_, url) => Container(
        color: placeHolderBackground ? AppResources.colorGrey : null,
        child: CtProgressIndicator(),
      ),
      errorBuilder: (_, url, error) => errorWidget,
    );
  }
}
