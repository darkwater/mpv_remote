import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mpv_remote/mpv_socket.dart';
import 'package:mpv_remote/widgets/property_builder.dart';
import 'package:provider/provider.dart';

class Zoom extends StatefulWidget {
  const Zoom({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(
      builder: (_) => const Zoom(),
    );
  }

  @override
  _ZoomState createState() => _ZoomState();
}

class _ZoomState extends State<Zoom> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      height: double.infinity,
      child: PropertyBuilder(
        properties: const [
          "video-params/aspect",
          MpvProperty.videoZoom,
          MpvProperty.videoAlignX,
          MpvProperty.videoAlignY,
        ],
        builder: (context, props) {
          final aspect = props["video-params/aspect"] as double? ?? (16 / 9);
          final zoom = props.videoZoom ?? 0.0;
          final alignX = props.videoAlignX ?? 0.0;
          final alignY = props.videoAlignY ?? 0.0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AspectRatio(
                  aspectRatio: aspect,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onHorizontalDragStart: (details) {
                          // claim this gesture
                        },
                        onHorizontalDragUpdate: (details) => _handleDrag(
                          constraints.biggest,
                          details.localPosition,
                          zoom,
                        ),
                        onPanUpdate: (details) => _handleDrag(
                          constraints.biggest,
                          details.localPosition,
                          zoom,
                        ),
                        child: AspectBordered(
                          aspect: aspect,
                          borderColor: Theme.of(context).dividerColor,
                          child: Align(
                            alignment: Alignment(alignX, alignY),
                            child: FractionallySizedBox(
                              widthFactor: pow(2, -zoom).toDouble(),
                              child: AspectBordered(
                                aspect: aspect,
                                borderColor:
                                    Theme.of(context).colorScheme.primary,
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.zoom_out),
                    Expanded(
                      child: SizedBox(
                        height: 100,
                        child: Slider(
                          value: zoom,
                          min: 0,
                          max: max(zoom, 3),
                          onChanged: (v) {
                            if (v < 0.1) v = 0;
                            context.read<MpvSocket>().videoZoom = v;
                          },
                        ),
                      ),
                    ),
                    const Icon(Icons.zoom_in),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleDrag(Size parent, Offset pos, double zoom) {
    if (zoom == 0) {
      context.read<MpvSocket>().videoAlignX = 0;
      context.read<MpvSocket>().videoAlignY = 0;

      return;
    }

    final normalizedShownWidth = parent.width * pow(2, -zoom).toDouble();
    final normalizedShownHeight = parent.height * pow(2, -zoom).toDouble();

    final normalizedX = pos.dx / parent.width;
    final centeredX = (normalizedX - 0.5) * 2;
    final paddedX =
        centeredX * parent.width / (parent.width - normalizedShownWidth);
    final clampedX = paddedX.clamp(-1, 1);
    final x = clampedX.toDouble();

    final normalizedY = pos.dy / parent.height;
    final centeredY = (normalizedY - 0.5) * 2;
    final paddedY =
        centeredY * parent.height / (parent.height - normalizedShownHeight);
    final clampedY = paddedY.clamp(-1, 1);
    final y = clampedY.toDouble();

    context.read<MpvSocket>().videoAlignX = x;
    context.read<MpvSocket>().videoAlignY = y;
  }
}

class AspectBordered extends StatelessWidget {
  const AspectBordered({
    required this.aspect,
    required this.borderColor,
    this.fillColor = Colors.transparent,
    this.width,
    this.child,
    Key? key,
  }) : super(key: key);

  final double aspect;
  final Color borderColor;
  final Color fillColor;
  final double? width;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspect,
      child: Container(
        constraints:
            BoxConstraints.tight(Size.fromWidth(width ?? double.infinity)),
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
