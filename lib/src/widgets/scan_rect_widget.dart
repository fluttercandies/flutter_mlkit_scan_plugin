///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/6/1 16:24
///
import 'dart:async';

import 'package:flutter/material.dart';

import '../plugin/constants.dart';
import '../resources.dart';
import 'scan_rect_painter.dart';

class ScanRectWidget extends ImplicitlyAnimatedWidget {
  const ScanRectWidget({
    Key? key,
    required this.height,
    required this.padding,
    this.tipBuilder,
    this.result,
    this.description,
    Curve curve = Curves.easeOutQuart,
    required Duration duration,
    VoidCallback? onEnd,
  }) : super(key: key, curve: curve, duration: duration, onEnd: onEnd);

  final double height;
  final EdgeInsets padding;

  /// 中间部分提示展示
  final WidgetBuilder? tipBuilder;

  /// 结果展示
  final String? result;

  /// 底部描述展示
  final String? description;

  @override
  _ScanRectWidgetState createState() => _ScanRectWidgetState();
}

class _ScanRectWidgetState extends AnimatedWidgetBaseState<ScanRectWidget> {
  late final ValueNotifier<bool> _isResultDisplaying =
      ValueNotifier<bool>(widget.result != null);

  Tween<double>? _height;
  Timer? _resultDisplayTimer;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _height = visitor(
      _height,
      widget.height,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  void didUpdateWidget(ScanRectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.result != null) {
      _showResult();
    } else {
      _isResultDisplaying.value = false;
    }
  }

  void _showResult() {
    _isResultDisplaying.value = true;
    _resultDisplayTimer?.cancel();
    _resultDisplayTimer = Timer(const Duration(seconds: 3), () {
      _isResultDisplaying.value = false;
    });
  }

  Widget _tipWidget(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(
        color: Colors.grey[600],
        height: 1.2,
        fontSize: 34,
        fontWeight: FontWeight.bold,
      ),
      child: widget.tipBuilder!(context),
    );
  }

  Widget _resultWidget(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).dividerColor.withOpacity(.25),
        ),
        child: Text(
          widget.result!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _descriptionWidget(BuildContext context, Size size) {
    return Container(
      width: size.width,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999999),
        color: Theme.of(context).dividerColor.withOpacity(.25),
      ),
      child: Text(
        widget.description!,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double evaluatingHeight = _height!.evaluate(animation);
    final Size size = Size(
      screenWidth - widget.padding.horizontal,
      evaluatingHeight,
    );
    return Material(
      type: MaterialType.transparency,
      child: SizedBox.fromSize(
        size: Size(screenWidth, evaluatingHeight),
        child: CustomPaint(
          size: size,
          painter: ScanRectPainter(
            height: evaluatingHeight,
            padding: widget.padding,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: double.maxFinite,
                  height: evaluatingHeight,
                  margin: widget.padding,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      if (widget.tipBuilder != null) _tipWidget(context),
                      _ScanLineWidget(size),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isResultDisplaying,
                        builder: (_, bool value, __) => Positioned.fill(
                          top: null,
                          child: AnimatedSwitcher(
                            duration: kThemeChangeDuration,
                            child: value
                                ? _resultWidget(context)
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.description != null)
                  _descriptionWidget(context, size),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanLineWidget extends StatefulWidget {
  const _ScanLineWidget(this.size, {Key? key}) : super(key: key);

  final Size size;

  @override
  _ScanLineWidgetState createState() => _ScanLineWidgetState();
}

class _ScanLineWidgetState extends State<_ScanLineWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    upperBound: .9,
    duration: const Duration(seconds: 5),
    vsync: this,
  )..repeat();
  late final CurvedAnimation _animation = CurvedAnimation(
    curve: Curves.easeInOutQuad,
    parent: _controller,
  );

  @override
  void didUpdateWidget(_ScanLineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.size != oldWidget.size) {
      _controller
        ..stop()
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, Widget? child) => Transform.translate(
          offset: Offset(0, _animation.value * widget.size.height),
          child: child,
        ),
        child: Image.asset(
          ScanPluginR.ASSETS_SCAN_LINE_PNG,
          package: ScanPluginPackage,
        ),
      ),
    );
  }
}
