import 'package:flutter/material.dart';

class FillRemainsScrollView extends StatelessWidget {
  const FillRemainsScrollView({
    Key? key,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    this.child,
    this.builder,
  }) : super(key: key);

  /// The axis along which the scroll view scrolls. Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// An object that can be used to control the position to which this scroll view is scrolled.
  final ScrollController? controller;

  /// How the scroll view should respond to user input.
  final ScrollPhysics? physics;

  /// Child widget
  final Widget? child;

  /// Optional widget builder that's just above the internal [SingleChildScrollView].
  final Widget Function(BuildContext context, SingleChildScrollView child)? builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final child = SingleChildScrollView(
          scrollDirection: scrollDirection,
          controller: controller,
          physics: physics,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: scrollDirection == Axis.horizontal ? box.maxWidth : 0,
              minHeight: scrollDirection == Axis.vertical ? box.maxHeight : 0,
            ),
            child: this.child,
          ),
        );

        return builder?.call(context, child) ?? child;
      },
    );
  }
}
