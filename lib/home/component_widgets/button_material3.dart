import 'package:flutter/material.dart';

class Material3Button extends StatelessWidget {
  const Material3Button({
    required this.handleMaterialVersionChange,
    this.showTooltipBelow = true,
  });

  final void Function() handleMaterialVersionChange;
  final bool showTooltipBelow;

  @override
  Widget build(BuildContext context) {
    final useMaterial3 = Theme.of(context).useMaterial3;
    return Tooltip(
      preferBelow: showTooltipBelow,
      message: 'Switch to Material ${useMaterial3 ? 2 : 3}',
      child: IconButton(
        icon: useMaterial3
            ? const Icon(Icons.filter_2)
            : const Icon(Icons.filter_3),
        onPressed: handleMaterialVersionChange,
      ),
    );
  }
}

class Material3MenuItemButton extends StatelessWidget {
  const Material3MenuItemButton({
    required this.handleMaterialVersionChange,
    this.showTooltipBelow = true,
  });

  final void Function() handleMaterialVersionChange;
  final bool showTooltipBelow;

  @override
  Widget build(BuildContext context) {
    final useMaterial3 = Theme.of(context).useMaterial3;
    return MenuItemButton(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.spaceAround,
        children: [
          useMaterial3
              ? const SizedBox(
                  width: 100,
                  child: Padding(
                      padding: EdgeInsets.only(left: 5),
                      child: Text('Material 3')))
              : const SizedBox(
                  width: 100,
                  child: Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: Text('Material 2'),
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
                child:           Switch(
                    value: useMaterial3,
                    onChanged: (_) {
                      handleMaterialVersionChange();
                    })
              ))
        ],
      ),
    );
  }
}
