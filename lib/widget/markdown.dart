import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/comment.dart';

class MarkdownWidget extends StatefulWidget {
  ///the markdown data
  final String data;

  ///if [tocController] is not null, you can use [tocListener] to get current TOC index
  final TocController? tocController;

  ///set the desired scroll physics for the markdown item list
  final ScrollPhysics? physics;

  ///set shrinkWrap to obtained [ListView] (only available when [tocController] is null)
  final bool shrinkWrap;

  /// [ListView] padding
  final EdgeInsetsGeometry? padding;

  ///make text selectable
  final bool selectable;

  ///the configs of markdown
  final MarkdownConfig? config;

  ///config for [MarkdownGenerator]
  final MarkdownGenerator? markdownGenerator;

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
  }) : super(key: key);

  @override
  MarkdownWidgetState createState() => MarkdownWidgetState();
}

class MarkdownWidgetState extends State<MarkdownWidget> {
  ///use [markdownGenerator] to transform markdown data to [Widget] list
  late MarkdownGenerator markdownGenerator;

  ///The markdown string converted by MarkdownGenerator will be retained in the [_widgets]
  final List<Widget> _widgets = [];

  ///[TocController] combines [TocWidget] and [MarkdownWidget]
  TocController? _tocController;

  ///[AutoScrollController] provides the scroll to index mechanism
  final AutoScrollController controller = AutoScrollController();

  ///every [VisibilityDetector]'s child which is visible will be kept with [indexTreeSet]
  final indexTreeSet = SplayTreeSet<int>((a, b) => a - b);

  ///if the [ScrollDirection] of [ListView] is [ScrollDirection.forward], [isForward] will be true
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

  ///when we've got the data, we need update data without setState() to avoid the flicker of the view
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

  ///this method will be called when [updateState] or [dispose]
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

  ///
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
            // This is the last index, return the comment form widget
            return _buildCommentForm();
          } else {
            // Return the original widget wrapped with auto scroll and visibility detector
            return wrapByAutoScroll(index,
                wrapByVisibilityDetector(index, _widgets[index]), controller);
          }
        },
        itemCount: _widgets.length + 1, // Add 1 for the comment form
        padding: widget.padding,
      ),
    );
    return widget.selectable
        ? SelectionArea(child: markdownWidget)
        : markdownWidget;
  }

  ///wrap widget by [VisibilityDetector] that can know if [child] is visible
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

  Widget _buildCommentForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Leave a Comment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
          ),
          SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Author Name',
              hintText: 'Enter your name',
              fillColor: Theme.of(context).colorScheme.surface,
              filled: true,
            ),
            keyboardType: TextInputType.name,
          ),
          SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your comment here',
              fillColor: Theme.of(context).colorScheme.surface,
              filled: true,
            ),
            keyboardType: TextInputType.multiline,
            maxLines: null,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement comment submission logic
            },
            child: Text('Submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    // TODO: Fetch comments from Firebase and build the list
    return FutureBuilder(
      // Your Firebase comments fetching logic goes here
      future: null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error fetching comments'));
        } else {
          // Assuming your comments are in 'snapshot.data'
          final comments = snapshot.data as List<Comment>;
          return ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return ListTile(
                title: Text(comment.authorName),
                subtitle: Text(comment.content),
                leading: Icon(Icons.comment),
              );
            },
          );
        }
      },
    );
  }

  @override
  void didUpdateWidget(MarkdownWidget oldWidget) {
    clearState();
    updateState();
    super.didUpdateWidget(widget);
  }
}

///wrap widget by [AutoScrollTag] that can use [AutoScrollController] to scrollToIndex
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
