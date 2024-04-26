import 'package:flutter/material.dart';

class UsingBottomBarMenuItemButton extends StatelessWidget {
  const UsingBottomBarMenuItemButton(
      {required this.handleUsingBottomBarChange, required this.useBottomBar});

  final void Function() handleUsingBottomBarChange;
  final bool useBottomBar;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.spaceAround,
        children: [
          useBottomBar
              ? const SizedBox(
                  width: 100,
                  child: Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Text('Show BottomBar')))
              : const SizedBox(
                  width: 100,
                  child: Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Text('Hide BottomBar'),
                  ),
                ),

          const SizedBox(
            width: 20,
          ),
          // Switch(
          //     value: useMaterial3,
          //     onChanged: (_) {
          //       handleMaterialVersionChange();
          //     })
          SizedBox(
              width: 50,
              child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Switch(
                      value: useBottomBar,
                      onChanged: (_) {
                        handleUsingBottomBarChange();
                      })))
        ],
      ),
    );
  }
}
