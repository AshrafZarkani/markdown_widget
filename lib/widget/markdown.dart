import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MarkdownWidget extends StatefulWidget {
  final String data;
  final TocController? tocController;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final bool selectable;
  final EdgeInsetsGeometry? padding;
  final MarkdownConfig? config;
  final MarkdownGenerator? markdownGenerator;
  final Widget? commentWidget;

  const MarkdownWidget({
    Key? key,
    required this.data,
    this.tocController,
    this.physics,
    this.shrinkWrap = false,
    this.selectable = true,
    this.padding,
    this.config,
    this.markdownGenerator,
    this.commentWidget,
  }) : super(key: key);

  @override
  MarkdownWidgetState createState() => MarkdownWidgetState();
}

class MarkdownWidgetState extends State<MarkdownWidget> {
  late MarkdownGenerator markdownGenerator;
  final List<Widget> _widgets = [];
  TocController? _tocController;
  final AutoScrollController controller = AutoScrollController();
  final indexTreeSet = SplayTreeSet<int>((a, b) => a - b);
  bool isForward = true;

  @override
  void initState() {
    super.initState();
    _tocController = widget.tocController;
    _tocController?.jumpToIndexCallback = (index) {
      controller.scrollToIndex(index, preferPosition: AutoScrollPosition.begin);
    };
    updateState();
  }

  void updateState() {
    indexTreeSet.clear();
    markdownGenerator = widget.markdownGenerator ?? MarkdownGenerator();
    final result = markdownGenerator.buildWidgets(
      widget.data,
      onTocList: (tocList) {
        _tocController?.setTocList(tocList);
      },
      config: widget.config,
    );
    _widgets.addAll(result);
  }

  void clearState() {
    indexTreeSet.clear();
    _widgets.clear();
  }

  @override
  void dispose() {
    clearState();
    controller.dispose();
    _tocController?.jumpToIndexCallback = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildMarkdownWidget();

  Widget buildMarkdownWidget() {
    final markdownWidget = NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        final ScrollDirection direction = notification.direction;
        isForward = direction == ScrollDirection.forward;
        return true;
      },
      child: ListView.builder(
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        controller: controller,
        itemBuilder: (ctx, index) {
          if (index == _widgets.length) {
            return widget.commentWidget;
          } else {
            return wrapByAutoScroll(index,
                wrapByVisibilityDetector(index, _widgets[index]), controller);
          }
        },
        itemCount: _widgets.length + 1,
        padding: widget.padding,
      ),
    );
    return widget.selectable
        ? SelectionArea(child: markdownWidget)
        : markdownWidget;
  }

  Widget wrapByVisibilityDetector(int index, Widget child) {
    return VisibilityDetector(
      key: ValueKey(index.toString()),
      onVisibilityChanged: (VisibilityInfo info) {
        final visibleFraction = info.visibleFraction;
        if (isForward) {
          visibleFraction == 0
              ? indexTreeSet.remove(index)
              : indexTreeSet.add(index);
        } else {
          visibleFraction == 1.0
              ? indexTreeSet.add(index)
              : indexTreeSet.remove(index);
        }
        if (indexTreeSet.isNotEmpty) {
          _tocController?.onIndexChanged(indexTreeSet.first);
        }
      },
      child: child,
    );
  }

  @override
  void didUpdateWidget(MarkdownWidget oldWidget) {
    clearState();
    updateState();
    super.didUpdateWidget(widget);
  }
}

Widget wrapByAutoScroll(
    int index, Widget child, AutoScrollController controller) {
  return AutoScrollTag(
    key: Key(index.toString()),
    controller: controller,
    index: index,
    child: child,
    highlightColor: Colors.black.withOpacity(0.1),
  );
}
