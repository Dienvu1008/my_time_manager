import 'package:flutter/material.dart';
import 'package:my_time_manager/screen_tasks/component_widgets/button_color_seed.dart';
import 'package:my_time_manager/utils/constants.dart';

class TitleListTile extends StatefulWidget {
  final TextEditingController titleController;
  final bool isCompleted;
  final Color itemColor;
  final Function(int) handleColorSelect;

  TitleListTile({
    required this.titleController,
    required this.isCompleted,
    required this.itemColor,
    required this.handleColorSelect,
  });

  @override
  _TitleListTileState createState() => _TitleListTileState();
}

// class _TitleListTileState extends State<TitleListTile> {
//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       trailing: Padding(
//         padding: const EdgeInsets.only(left: 0.0, right: 0.0),
//         child: ColorSeedButton(
//           colorSelected: ColorSeed.values.firstWhere(
//             (e) => e.color.value == widget.itemColor.value,
//             orElse: () => ColorSeed.baseColor,
//           ),
//           handleColorSelect: widget.handleColorSelect,
//         ),
//       ),
//       title: TextField(
//         controller: widget.titleController,
//         style: TextStyle(
//           decoration: widget.isCompleted
//               ? TextDecoration.lineThrough
//               : TextDecoration.none,
//         ),
//         maxLines: null,
//         decoration: const InputDecoration(
//           hintText: 'Title',
//           border: InputBorder.none,
//         ),
//       ),
//     );
//   }
// }

class _TitleListTileState extends State<TitleListTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          trailing: Padding(
            padding: const EdgeInsets.only(left: 0.0, right: 0.0),
            child: ColorSeedButton(
              colorSelected: ColorSeed.values.firstWhere(
                (e) => e.color.value == widget.itemColor.value,
                orElse: () => ColorSeed.baseColor,
              ),
              handleColorSelect: widget.handleColorSelect,
            ),
          ),
          title: TextField(
            controller: widget.titleController,
            style: TextStyle(
              decoration: widget.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: InputBorder.none,
            ),
          ),
        ),
        const Divider(
          height: 4,
        ),
      ],
    );
  }
}
