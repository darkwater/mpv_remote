import 'package:flutter/material.dart';

import 'first_half.dart';
import 'second_half.dart';

class Controls extends StatelessWidget {
  const Controls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final mainAxis = (constraints.maxWidth < constraints.maxHeight)
          ? Axis.vertical
          : Axis.horizontal;

      return Flex(
        direction: mainAxis,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Expanded(
            child: FirstHalf(),
          ),
          Expanded(
            child: SecondHalf(),
          ),
        ],
      );
    });
  }
}
