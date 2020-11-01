import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinetime/services/web_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

class CtProgressIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitCubeGrid(
        color: Colors.red,
      )
    );
  }
}


class CtCachedImage extends StatelessWidget {
  final String path;
  final bool isThumbnail;
  final bool applyDarken;   //TODO find better name

  const CtCachedImage({Key key, this.path, this.isThumbnail, this.applyDarken}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var errorWidget = Center(
      child: Icon(Icons.image),
    );

    if (path?.isNotEmpty != true)
      return errorWidget;

    return CachedNetworkImage(
      imageUrl: WebServices.getImageUrl(path, isThumbnail),
      placeholder: (_, url) => CtProgressIndicator(),
      errorWidget: (_, url, error) => errorWidget,
      fit: BoxFit.cover,
      color: applyDarken == true ? Colors.black.withOpacity(0.3) : null,
      colorBlendMode: BlendMode.srcATop,
    );
  }
}