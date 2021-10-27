import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinetime/resources/_resources.dart';
import 'package:cinetime/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CtProgressIndicator extends StatelessWidget {
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
  const CtAnimatedSwitcher({Key? key, this.child, this.sizeAnimation = false}) : super(key: key);

  /// The current child widget to display
  final Widget? child;

  /// Will also animate it's size with a [SizeTransition].
  /// Be aware that this will add a ClipRect.
  final bool sizeAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppResources.durationAnimationMedium,
      transitionBuilder: sizeAnimation == true
        ? (child, animation) => FadeTransition(child: SizeTransition(child: child, sizeFactor: animation, axisAlignment: -1), opacity: animation)
        : AnimatedSwitcher.defaultTransitionBuilder,
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
