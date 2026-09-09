import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app.dart';
import '../../screen_material_design/page_component.dart';
import 'transition_bar.dart';
import 'transition_rail.dart';

class NavigationTransition extends StatefulWidget {
  const NavigationTransition(
      {super.key,
      required this.scaffoldKey,
      required this.animationController,
      required this.railAnimation,
      required this.navigationRail,
      this.navigationBar,
      required this.drawer,
      this.appBar,
      required this.body,
      //this.appBarBodyWidget,
      });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final AnimationController animationController;
  final CurvedAnimation railAnimation;
  final Widget navigationRail;
  final Widget? navigationBar;
  final Widget drawer;
  final PreferredSizeWidget? appBar;
  final Widget body;
  //final Widget? appBarBodyWidget;

  @override
  State<NavigationTransition> createState() => _NavigationTransitionState();
}

class _NavigationTransitionState extends State<NavigationTransition> {
  late final AnimationController controller;
  late final CurvedAnimation railAnimation;
  late final ReverseAnimation barAnimation;
  bool controllerInitialized = false;
  bool showDivider = false;

  @override
  void initState() {
    super.initState();

    controller = widget.animationController;
    railAnimation = widget.railAnimation;

    barAnimation = ReverseAnimation(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // Khi bottom bar ở chế độ trong suốt, cho body trải xuống DƯỚI thanh điều
    // hướng (extendBody) để nội dung thực sự nhìn thấy phía sau thanh, thay vì
    // bị thanh chiếm chỗ trong layout.
    final transparentBar =
        context.select((AppBloc b) => b.state.transparentBottomBar);

    return Scaffold(
      key: widget.scaffoldKey,
      extendBody: transparentBar,
      appBar: widget.appBar,
      body: Row(
        children: <Widget>[
          RailTransition(
            animation: railAnimation,
            backgroundColor: colorScheme.surface,
            child: widget.navigationRail,
          ),
          widget.body,
        ],
      ),
      bottomNavigationBar: BarTransition(
        animation: barAnimation,
        backgroundColor: Colors.transparent, //colorScheme.surface,
        child: widget.navigationBar,
      ),
      drawer: Drawer(
        backgroundColor: colorScheme.surface,
        child: widget.drawer,
      ),
      endDrawer: const NavigationDrawerSection(),
    );
  }
}
