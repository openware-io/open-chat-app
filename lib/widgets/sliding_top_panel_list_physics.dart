import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

/// Scroll physics for a top-revealed [SlidingUpPanel].
///
/// When the list is at the top and the user drags down, the gesture opens the
/// panel instead of stretching the list. Once the panel is visible, vertical
/// drags continue to drive the panel until it is closed.
class SlidingTopPanelListPhysics extends ScrollPhysics {
  const SlidingTopPanelListPhysics({
    required this.panelController,
    required this.maxPanelHeight,
    required this.scrollController,
    super.parent,
  });

  final PanelController panelController;
  final double maxPanelHeight;
  final ScrollController scrollController;

  static const double _eps = 0.001;

  @override
  SlidingTopPanelListPhysics applyTo(ScrollPhysics? ancestor) {
    return SlidingTopPanelListPhysics(
      panelController: panelController,
      maxPanelHeight: maxPanelHeight,
      scrollController: scrollController,
      parent: buildParent(ancestor),
    );
  }

  double _openDamp(double position) {
    final room = (1.0 - position).clamp(0.0, 1.0);
    return 0.2 + 0.8 * room * room;
  }

  void _pinTop() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.pixels < position.minScrollExtent) {
      scrollController.jumpTo(position.minScrollExtent);
    }
  }

  void _applyPanel(double offset) {
    if (!panelController.isAttached || maxPanelHeight <= 0) return;
    var position = panelController.panelPosition;
    final range = maxPanelHeight;
    if (offset > 0) {
      position =
          (position + offset * _openDamp(position) / range).clamp(0.0, 1.0);
    } else if (offset < 0) {
      position = (position - (-offset) / range).clamp(0.0, 1.0);
    }
    panelController.panelPosition = position;
    _pinTop();
  }

  double get _panelPosition =>
      panelController.isAttached ? panelController.panelPosition : 0.0;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (parent == null) return offset;

    if (_panelPosition > _eps) {
      _applyPanel(offset);
      return 0;
    }

    final atTop = position.pixels <= position.minScrollExtent + 1.0;
    if (atTop && offset > 0) {
      _applyPanel(offset);
      return 0;
    }

    return parent!.applyPhysicsToUserOffset(position, offset);
  }
}
