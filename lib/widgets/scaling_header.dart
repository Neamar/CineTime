import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

/// Copied from https://github.com/figengungor/scaling_header/blob/master/lib/scaling_header.dart
class ScalingHeader extends StatefulWidget {
  ScalingHeader(
      {Key? key,
      this.leading,
      this.automaticallyImplyLeading = true,
      this.title,
      this.actions,
      this.bottom,
      this.elevation = 0,
      this.backgroundColor,
      this.brightness,
      this.iconTheme,
      this.textTheme,
      this.primary = true,
      this.centerTitle,
      this.titleSpacing = NavigationToolbar.kMiddleSpacing,
      this.bottomOpacity = 1.0,
      this.flexibleSpace,
      this.flexibleSpaceHeight = 275,
      this.overlapContentHeight = 50,
      this.overlapContentWidth = 300,
      required this.overlapContent,
      required this.overlapContentBackgroundColor,
      this.overlapContentRadius = 30});

  /// See [AppBar.leading]
  final Widget? leading;

  /// See [AppBar.automaticallyImplyLeading]
  final bool automaticallyImplyLeading;

  /// See [AppBar.title]
  final Widget? title;

  /// See [AppBar.actions]
  final List<Widget>? actions;

  /// See [AppBar.bottom]
  final PreferredSizeWidget? bottom;

  /// See [AppBar.elevation]
  final double elevation;

  /// See [AppBar.backgroundColor]
  final Color? backgroundColor;

  /// See [AppBar.brightness]
  final Brightness? brightness;

  /// See [AppBar.iconTheme]
  final IconThemeData? iconTheme;

  /// See [AppBar.textTheme]
  final TextTheme? textTheme;

  /// See [AppBar.primary]
  final bool primary;

  /// See [AppBar.centerTitle]
  final bool? centerTitle;

  /// See [AppBar.titleSpacing]
  final double titleSpacing;

  /// See [AppBar.bottomOpacity]
  final double bottomOpacity;

  /// Expanded widget, usually an Image
  final Widget? flexibleSpace;

  /// Max height of [flexibleSpace]
  final double flexibleSpaceHeight;

  /// The height of [overlapContent]
  final double overlapContentHeight;

  /// The width of [overlapContent]
  final double overlapContentWidth;

  ///The content widget that is centered onto bottom of [flexibleSpace]
  final Widget overlapContent;

  ///The background color of [overlapContent]
  final Color overlapContentBackgroundColor;

  ///The radius of [overlapContent]
  final double overlapContentRadius;

  @override
  _ScalingHeaderState createState() => _ScalingHeaderState();
}

class _ScalingHeaderState extends State<ScalingHeader>
    with SingleTickerProviderStateMixin {
  ValueNotifier<double> _shrinkOffsetNotifier = ValueNotifier<double>(0);
  late AnimationController _animationController;
  bool _isExpanded = true;
  double? expandedHeight;
  double? overlapContentHeight;
  double? overlapContentWidth;

  @override
  void initState() {
    expandedHeight =
        widget.flexibleSpaceHeight + widget.overlapContentHeight / 2;
    overlapContentHeight = widget.overlapContentHeight;
    overlapContentWidth = widget.overlapContentWidth;

    _shrinkOffsetNotifier.addListener(() {
      final offset =
          expandedHeight! - (kToolbarHeight + overlapContentHeight! / 2);
      if (_isExpanded && _shrinkOffsetNotifier.value > offset) {
        _isExpanded = false;
        _animationController.forward();
      } else if (!_isExpanded && _shrinkOffsetNotifier.value < offset) {
        _isExpanded = true;
        _animationController.reverse();
      }
    });

    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));

    _animationController.addListener(() => setState(() {}));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      leading: widget.leading,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      title: widget.title,
      actions: widget.actions,
      bottom: widget.bottom,
      elevation: widget.elevation,
      backgroundColor: widget.backgroundColor != null
          ? widget.backgroundColor!.withOpacity(_animationController.value)
          : Theme.of(context)
              .primaryColor
              .withOpacity(_animationController.value),
      brightness: widget.brightness,
      iconTheme: widget.iconTheme,
      textTheme: widget.textTheme,
      primary: widget.primary,
      centerTitle: widget.centerTitle,
      titleSpacing: widget.titleSpacing,
      bottomOpacity: widget.bottomOpacity,
    );

    return SliverPersistentHeader(
      delegate: Header(
          expandedHeight,
          overlapContentHeight,
          overlapContentWidth,
          _shrinkOffsetNotifier,
          appBar,
          widget.flexibleSpace,
          widget.overlapContent,
          widget.overlapContentBackgroundColor,
          widget.overlapContentRadius,
          MediaQuery.of(context).padding.top),
      pinned: true,
    );
  }
}

class Header extends SliverPersistentHeaderDelegate {
  Header(
      this.expandedHeight,
      this.overlapContentHeight,
      this.overlapContentWidth,
      this.shrinkOffsetNotifier,
      this.appBar,
      this.flexibleSpace,
      this.overlapContent,
      this.overlapContentBackgroundColor,
      this.overlapContentRadius,
      this.topPadding);

  final ValueNotifier<double> shrinkOffsetNotifier;
  final double? expandedHeight;
  final double? overlapContentHeight;
  final double? overlapContentWidth;
  final PreferredSizeWidget appBar;
  final Widget? flexibleSpace;
  final Widget overlapContent;
  final Color overlapContentBackgroundColor;
  final double overlapContentRadius;
  final double topPadding;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    shrinkOffsetNotifier.value = shrinkOffset;
    final width = MediaQuery.of(context).size.width;
    final offset =
        expandedHeight! - (kToolbarHeight + topPadding + overlapContentHeight!);
    final distance = width - overlapContentWidth!;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              //height: overlapContentHeight,
              bottom: overlapContentHeight! / 2,
              child: flexibleSpace!,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: appBar,
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: overlapContentBackgroundColor,
                borderRadius: BorderRadius.circular(overlapContentRadius -
                    overlapContentRadius / offset * shrinkOffset),
              ),
              height: overlapContentHeight,
              width: distance / offset * shrinkOffset + overlapContentWidth!,
              child: overlapContent,
            ),
          ),
        )
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight!;

  @override
  double get minExtent => kToolbarHeight + topPadding + overlapContentHeight!;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    Header oldie = oldDelegate as Header;
    return expandedHeight != oldie.expandedHeight ||
        overlapContentHeight != oldie.overlapContentHeight ||
        overlapContentWidth != oldie.overlapContentWidth ||
        shrinkOffsetNotifier != oldie.shrinkOffsetNotifier ||
        appBar != oldie.appBar ||
        flexibleSpace != oldie.flexibleSpace ||
        overlapContent != oldie.overlapContent ||
        overlapContentBackgroundColor != oldie.overlapContentBackgroundColor ||
        overlapContentRadius != oldie.overlapContentRadius ||
        topPadding != oldie.topPadding;
  }
}
