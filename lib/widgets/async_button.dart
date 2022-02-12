import 'package:flutter/material.dart';

class AsyncButton extends StatefulWidget {
  final Future<bool> Function()? onPressed;
  final String label;

  const AsyncButton({
    Key? key,
    this.onPressed,
    required this.label,
  }) : super(key: key);

  @override
  _AsyncButtonState createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  Widget? overlayWidget;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: overlayWidget != null || widget.onPressed == null
          ? null
          : () async {
              setState(() {
                overlayWidget = const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                );
              });

              bool success;
              try {
                success = await widget.onPressed!();
              } catch (e) {
                print("Async button callback error: $e");
                success = false;
              }

              if (!mounted) return;

              if (success) {
                setState(() {
                  overlayWidget = Transform.scale(
                    scale: 1.5,
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.green,
                    ),
                  );
                });
              } else {
                setState(() {
                  overlayWidget = Transform.scale(
                    scale: 1.5,
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.red,
                    ),
                  );
                });
              }

              await Future.delayed(const Duration(milliseconds: 1000));

              if (!mounted) return;

              setState(() => overlayWidget = null);
            },
      child: Stack(
        children: [
          Opacity(
            opacity: overlayWidget != null ? 0.2 : 1,
            child: Text(widget.label),
          ),
          if (overlayWidget != null)
            Positioned.fill(
              child: Center(
                child: overlayWidget,
              ),
            ),
        ],
      ),
    );
  }
}
