import 'package:flutter/material.dart';
import 'package:mpv_remote/widgets/property_builder.dart';

class FirstHalf extends StatelessWidget {
  const FirstHalf({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyBuilder(
      properties: const [
        MpvProperty.mediaTitle,
      ],
      builder: (context, props) {
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                props.mediaTitle ?? "",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
          ],
        );
      },
    );
  }
}
