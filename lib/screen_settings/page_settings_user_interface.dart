import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_time_manager/app/app.dart';
import 'package:my_time_manager/app/app_localizations.dart';
import 'package:my_time_manager/utils/constants.dart';

import 'calendar_sync_settings_card.dart';
import '../home/component_widgets/button_color_image.dart';
import '../home/component_widgets/button_color_seed.dart';
import '../home/component_widgets/button_language.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.useLightMode,
    required this.useMaterial3,
    required this.showBrightnessButtonInAppBar,
    required this.showMaterialDesignButtonInAppBar,
    required this.showColorSeedButtonInAppBar,
    required this.showColorImageButtonInAppBar,
    required this.showLanguagesButtonInAppBar,
    required this.colorSelected,
    required this.handleBrightnessChange,
    required this.handleMaterialVersionChange,
    required this.handleDisplayBrightnessButtonInAppBarChange,
    required this.handleDisplayMaterialDesignButtonInAppBarChange,
    required this.handleDisplayColorSeedButtonInAppBarChange,
    required this.handleDisplayColorImageButtonInAppBarChange,
    required this.handleDisplayLanguagesButtonInAppBarChange,
    required this.handleColorSelect,
    required this.handleImageSelect,
    required this.handleLanguageSelect,
    required this.colorSelectionMethod,
    required this.imageSelected,
    required this.languageSelected,
    required this.launchCount,
  });

  final bool useLightMode;
  final bool useMaterial3;
  final bool showBrightnessButtonInAppBar;
  final bool showMaterialDesignButtonInAppBar;
  final bool showColorSeedButtonInAppBar;
  final bool showColorImageButtonInAppBar;
  final bool showLanguagesButtonInAppBar;
  final ColorSeed colorSelected;
  final ColorImageProvider imageSelected;
  final ColorSelectionMethod colorSelectionMethod;
  final AppLanguage languageSelected;
  final int launchCount;

  final void Function(bool useLightMode) handleBrightnessChange;
  final void Function() handleMaterialVersionChange;
  final void Function() handleDisplayBrightnessButtonInAppBarChange;
  final void Function() handleDisplayMaterialDesignButtonInAppBarChange;
  final void Function() handleDisplayColorSeedButtonInAppBarChange;
  final void Function() handleDisplayColorImageButtonInAppBarChange;
  final void Function() handleDisplayLanguagesButtonInAppBarChange;
  final void Function(int value) handleColorSelect;
  final void Function(int value) handleImageSelect;
  final void Function(int value) handleLanguageSelect;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Expanded(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        localizations!.userInterfaceSettings,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ListTile(
                      leading: Theme.of(context).brightness == Brightness.light
                          ? const Icon(Icons.dark_mode_outlined)
                          : const Icon(Icons.light_mode_outlined),
                      title: Text(localizations.brightness),
                      trailing: Switch(
                          value: widget.useLightMode,
                          onChanged: (value) {
                            widget.handleBrightnessChange(value);
                          }),
                    ),
                    ListTile(
                      leading: widget.useMaterial3
                          ? const Icon(Icons.filter_3)
                          : const Icon(Icons.filter_2),
                      title: widget.useMaterial3
                          ? const Text("Material Design 3")
                          : const Text("Material Design 2"),
                      trailing: Switch(
                          value: widget.useMaterial3,
                          onChanged: (_) {
                            widget.handleMaterialVersionChange();
                          }),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.palette_outlined,
                      ),
                      title: Text(localizations.chooseThemeColor),
                      trailing: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: ColorSeedButton(
                            handleColorSelect: widget.handleColorSelect,
                            colorSelected: widget.colorSelected,
                            colorSelectionMethod: widget.colorSelectionMethod,
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.image_outlined,
                      ),
                      title: Text(localizations.chooseThemeColorFromImageColor),
                      trailing: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: ColorImageButton(
                            handleImageSelect: widget.handleImageSelect,
                            imageSelected: widget.imageSelected,
                            colorSelectionMethod: widget.colorSelectionMethod,
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.language_outlined,
                      ),
                      title: Text(localizations.chooseApplicationLanguage),
                      trailing: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: LanguageButton(
                            handleLanguageSelect: widget.handleLanguageSelect,
                            languageSelected: widget.languageSelected,
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text(
                          localizations.showBrightnessButtonInApplicationBar),
                      trailing: Switch(
                          value: widget.showBrightnessButtonInAppBar,
                          onChanged: (_) {
                            widget
                                .handleDisplayBrightnessButtonInAppBarChange();
                          }),
                    ),
                    ListTile(
                      title: Text(localizations
                          .showMaterialDesignButtonInApplicationBar),
                      trailing: Switch(
                          value: widget.showMaterialDesignButtonInAppBar,
                          onChanged: (_) {
                            widget
                                .handleDisplayMaterialDesignButtonInAppBarChange();
                          }),
                    ),
                    ListTile(
                      title: Text(
                          localizations.showColorSeedButtonInApplicationBar),
                      trailing: Switch(
                          value: widget.showColorSeedButtonInAppBar,
                          onChanged: (_) {
                            widget.handleDisplayColorSeedButtonInAppBarChange();
                          }),
                    ),
                    ListTile(
                      title: Text(
                          localizations.showColorImageButtonInApplicationBar),
                      trailing: Switch(
                          value: widget.showColorImageButtonInAppBar,
                          onChanged: (_) {
                            widget
                                .handleDisplayColorImageButtonInAppBarChange();
                          }),
                    ),
                    ListTile(
                      title: Text(
                          localizations.showLanguagesButtonInApplicationBar),
                      trailing: Switch(
                          value: widget.showLanguagesButtonInAppBar,
                          onChanged: (_) {
                            widget.handleDisplayLanguagesButtonInAppBarChange();
                          }),
                    ),
                  ],
                ),
              ),
              // --- Cài đặt thẻ công việc (Overview) ---
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        localizations.taskCardStyle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    BlocBuilder<AppBloc, AppState>(
                      buildWhen: (prev, curr) =>
                          prev.taskCardStyle != curr.taskCardStyle,
                      builder: (context, state) {
                        return Column(
                          children: [
                            RadioListTile<TaskCardStyle>(
                              secondary:
                                  const Icon(Icons.rectangle_rounded),
                              title: Text(localizations.taskCardStyleFilled),
                              value: TaskCardStyle.filled,
                              groupValue: state.taskCardStyle,
                              onChanged: (value) {
                                if (value != null) {
                                  context
                                      .read<AppBloc>()
                                      .add(ChangeTaskCardStyle(value));
                                }
                              },
                            ),
                            RadioListTile<TaskCardStyle>(
                              secondary:
                                  const Icon(Icons.view_sidebar_outlined),
                              title:
                                  Text(localizations.taskCardStyleLeadingBar),
                              value: TaskCardStyle.leadingColorBar,
                              groupValue: state.taskCardStyle,
                              onChanged: (value) {
                                if (value != null) {
                                  context
                                      .read<AppBloc>()
                                      .add(ChangeTaskCardStyle(value));
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              // --- Cài đặt đồng hồ Pomodoro ---
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        'Đồng hồ tập trung',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    // Đọc trực tiếp từ AppBloc (được cung cấp ở tầng App).
                    BlocBuilder<AppBloc, AppState>(
                      buildWhen: (prev, curr) =>
                          prev.keepPomodoroRunningInBackground !=
                          curr.keepPomodoroRunningInBackground,
                      builder: (context, state) {
                        return SwitchListTile(
                          secondary: const Icon(Icons.timer_outlined),
                          title: const Text('Tiếp tục chạy khi rời màn hình'),
                          subtitle: const Text(
                              'Khi bật, đồng hồ vẫn chạy lúc bạn chuyển sang '
                              'màn hình khác và hiện một cửa sổ nổi cho biết '
                              'thời gian còn lại.'),
                          value: state.keepPomodoroRunningInBackground,
                          onChanged: (value) => context
                              .read<AppBloc>()
                              .add(ToggleKeepPomodoroRunning(value)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // --- Cài đặt thanh điều hướng ---
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        'Thanh điều hướng',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    BlocBuilder<AppBloc, AppState>(
                      buildWhen: (prev, curr) =>
                          prev.transparentBottomBar != curr.transparentBottomBar,
                      builder: (context, state) {
                        return SwitchListTile(
                          secondary: const Icon(Icons.blur_on_outlined),
                          title: const Text('Thanh dưới trong suốt'),
                          subtitle: const Text(
                              'Hiển thị thanh điều hướng dưới với nền trong '
                              'suốt, không đổ bóng — gọn và nhẹ hơn.'),
                          value: state.transparentBottomBar,
                          onChanged: (value) => context
                              .read<AppBloc>()
                              .add(ToggleTransparentBottomBar(value)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // --- Cài đặt lịch ---
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        'Lịch',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    BlocBuilder<AppBloc, AppState>(
                      buildWhen: (prev, curr) =>
                          prev.showCalendarZoomButtons !=
                          curr.showCalendarZoomButtons,
                      builder: (context, state) {
                        return SwitchListTile(
                          secondary: const Icon(Icons.zoom_in),
                          title: const Text('Hiện nút phóng to/thu nhỏ'),
                          subtitle: const Text(
                              'Hiển thị nút +/- trên lịch. Dù tắt, bạn vẫn có '
                              'thể phóng to/thu nhỏ bằng cách chụm hai ngón tay '
                              'hoặc giữ Ctrl và cuộn chuột.'),
                          value: state.showCalendarZoomButtons,
                          onChanged: (value) => context
                              .read<AppBloc>()
                              .add(ToggleShowCalendarZoomButtons(value)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // --- Cài đặt nhắc (thông báo) ---
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: Text(
                        'Nhắc',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    BlocBuilder<AppBloc, AppState>(
                      buildWhen: (prev, curr) =>
                          prev.remindersEnabled != curr.remindersEnabled,
                      builder: (context, state) {
                        return SwitchListTile(
                          secondary:
                              const Icon(Icons.notifications_active_outlined),
                          title: const Text('Bật nhắc bằng thông báo'),
                          subtitle: const Text(
                              'Gửi thông báo trước khi công việc bắt đầu theo '
                              'các mốc bạn đặt. Tắt để hủy toàn bộ nhắc.'),
                          value: state.remindersEnabled,
                          onChanged: (value) => context
                              .read<AppBloc>()
                              .add(ToggleRemindersEnabled(value)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // --- Đồng bộ Google Calendar ---
              const CalendarSyncSettingsCard(),
            ],
          ),
        ),
      ),
    );
  }
}
