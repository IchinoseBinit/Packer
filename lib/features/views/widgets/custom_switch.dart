import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';

class CustomSwitch extends StatefulWidget {
  final double width;
  final double height;
  final bool fromWareHouse;
  final Function()? onPressed;

  const CustomSwitch({
    super.key,
    this.width = 115,
    this.height = 40,
    this.fromWareHouse = false,
    this.onPressed,
  });

  @override
  CustomSwitchState createState() => CustomSwitchState();
}

class CustomSwitchState extends State<CustomSwitch> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(builder: (_, value, __) {
      return GestureDetector(
        onTap: () {
          value.toggleOnlineStatus(context, isFromWarehouse: widget.fromWareHouse, onPressed: widget.onPressed);
        },
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height / 2),
            color: value.isOnline ? Colors.green : Colors.grey,
          ),
          child: Stack(
            children: [
              Align(
                alignment: value.isOnline
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    value.isOnline ? 'ONLINE' : 'OFFLINE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              AnimatedAlign(
                alignment: value.isOnline
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Container(
                  width: widget.height - 4,
                  height: widget.height - 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
