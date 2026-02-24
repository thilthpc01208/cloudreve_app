import 'package:cloudreve_view/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeChangeBtn extends StatefulWidget {
  const ThemeChangeBtn({super.key, this.size = 40});
  final double size;

  @override
  State<StatefulWidget> createState() {
    return _ThemeChangeBtnState();
  }
}

class _ThemeChangeBtnState extends State<ThemeChangeBtn> {
  final Controller _controller = Get.find<Controller>();
  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: widget.size,
      onPressed: () {
        _controller.changeTheme();
      },
      tooltip: 'Theme follows system',
      icon: const Icon(Icons.brightness_auto),
      color: Theme.of(Get.context!).iconTheme.color,
    );
  }
}
