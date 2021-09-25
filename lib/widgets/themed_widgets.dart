import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinetime/resources/resources.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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
  final String? path;
  final bool isThumbnail;
  final bool applyDarken;   //TODO find better name
  final VoidCallback? onPressed;

  const CtCachedImage({Key? key, this.path, this.isThumbnail = false, this.applyDarken = false, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final errorWidget = Center(
      child: Icon(Icons.image),
    );

    if (path?.isNotEmpty != true)
      return errorWidget;

    return CachedNetworkImage(
      imageUrl: ApiClient.getImageUrl(path, isThumbnail: isThumbnail)!,
      imageBuilder: (_, image) => GestureDetector(
        onTap: onPressed,
        child: Image(
          image: image,
          fit: BoxFit.cover,
          color: applyDarken ? Colors.black.withOpacity(0.3) : null,
          colorBlendMode: BlendMode.srcATop,
        ),
      ),
      placeholder: (_, url) => CtProgressIndicator(),
      errorWidget: (_, url, error) => errorWidget,
    );
  }
}

class CtAnimatedSwitcher extends StatelessWidget {
  const CtAnimatedSwitcher({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppResources.durationAnimationMedium,
      layoutBuilder: _animatedSwitcherLayoutBuilder,
      child: child,
    );
  }

  /// Copied from AnimatedSwitcher.defaultLayoutBuilder
  static Widget _animatedSwitcherLayoutBuilder(Widget? currentChild, List<Widget> previousChildren) {
    return Stack(
      children: <Widget>[
        ...previousChildren,
        if (currentChild != null) currentChild,
      ],
      alignment: Alignment.topLeft,
    );
  }
}
