import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/pomodoro_bloc.dart';
import '../bloc/pomodoro_config.dart';
import '../data/focus_repository.dart';
import '../data/notification_service.dart';
import 'focus_stats_screen.dart';
import 'pomodoro_overlay_controller.dart';
import 'task_picker_sheet.dart';
import 'widgets/progress_ring.dart';

/// Màn hình Pomodoro Focus Timer, lấy cảm hứng từ Windows 11 Focus Sessions:
/// một vòng tròn tiến trình lớn ở giữa, chọn task phía trên, các nút điều khiển
/// phía dưới, và tùy chọn thời lượng.
///
/// Tự cung cấp [PomodoroBloc] với [FocusRepository] lấy từ context (được cung
/// cấp ở tầng trên). Dark mode được kế thừa tự động từ theme của app.
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key, this.initialTask});

  /// Task được chọn sẵn khi mở màn hình (ví dụ mở từ menu "Tập trung ngay bây
  /// giờ" của một task). Null nếu mở không kèm task.
  final SelectedTask? initialTask;

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  @override
  void initState() {
    super.initState();
    // Báo cho overlay biết người dùng đang ở màn Pomodoro -> ẩn cửa sổ nổi.
    PomodoroOverlayController.instance.enterPomodoroScreen();

    // PomodoroBloc được provide TOÀN CỤC ở tầng App (không tạo mới ở đây) để
    // timer chạy tiếp khi rời màn hình. Nếu mở kèm task và hiện KHÔNG có phiên
    // nào đang chạy, chọn sẵn task đó. Không ghi đè khi đang có phiên chạy để
    // tránh làm gián đoạn phiên hiện tại.
    final task = widget.initialTask;
    if (task != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final bloc = context.read<PomodoroBloc>();
        if (!bloc.state.isActive) {
          bloc.add(PomodoroTaskSelected(task));
        }
      });
    }
  }

  @override
  void dispose() {
    // Rời màn Pomodoro -> cho phép overlay hiện lại (nếu timer đang chạy).
    //
    // KHÔNG đổi ValueNotifier ngay trong dispose: lúc này cây widget đang bị
    // khóa, việc đổi giá trị sẽ khiến ValueListenableBuilder (trong overlay)
    // bị markNeedsBuild -> ném lỗi "widget tree was locked". Ta hoãn sang sau
    // frame hiện tại để việc rebuild diễn ra an toàn.
    final controller = PomodoroOverlayController.instance;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.leavePomodoroScreen();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const _PomodoroView();
  }
}

/// Trang Pomodoro đứng độc lập (có Scaffold + AppBar), dùng khi điều hướng tới
/// bằng Navigator (ví dụ từ menu task). Khác với [PomodoroScreen] vốn được nhúng
/// dưới dạng Expanded trong layout Home.
class PomodoroPage extends StatelessWidget {
  const PomodoroPage({super.key, this.initialTask});

  final SelectedTask? initialTask;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tập trung')),
      // Bọc trong Column để _PomodoroView (Expanded) có ràng buộc chiều cao.
      body: Column(
        children: [PomodoroScreen(initialTask: initialTask)],
      ),
    );
  }
}

class _PomodoroView extends StatelessWidget {
  const _PomodoroView();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BlocListener<PomodoroBloc, PomodoroState>(
        // Khi một giai đoạn hoàn tất trên desktop, hiện dialog trong app
        // (notification hệ thống không đáng tin trên desktop).
        listenWhen: (prev, curr) =>
            prev.status != curr.status &&
            curr.status == TimerStatus.completed,
        listener: (context, state) {
          if (NotificationService.instance.isDesktop) {
            _showCompletionDialog(context, state);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              const _TaskSelector(),
              const SizedBox(height: 24),
              const _PhaseChips(),
              const SizedBox(height: 24),
              const _TimerRing(),
              const SizedBox(height: 32),
              const _Controls(),
              const SizedBox(height: 24),
              const _SessionCounter(),
              const SizedBox(height: 8),
              _BottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, PomodoroState state) {
    // state.phase ở đây đã là giai đoạn KẾ TIẾP (đã chuyển). Giai đoạn vừa xong
    // là focus nếu giai đoạn kế tiếp là break, và ngược lại.
    final justFinishedFocus = state.phase != PomodoroPhase.focus;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          justFinishedFocus ? Icons.celebration : Icons.self_improvement,
          size: 40,
        ),
        title: Text(justFinishedFocus ? 'Hoàn thành!' : 'Hết giờ nghỉ'),
        content: Text(
          justFinishedFocus
              ? 'Bạn đã hoàn thành một phiên tập trung. '
                  'Nghỉ ngơi một chút rồi tiếp tục nhé.'
              : 'Đã sẵn sàng cho phiên tập trung tiếp theo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<PomodoroBloc>().add(const PomodoroStarted());
            },
            child: Text(justFinishedFocus ? 'Bắt đầu nghỉ' : 'Bắt đầu tập trung'),
          ),
        ],
      ),
    );
  }
}

/// Ô chọn task để focus.
class _TaskSelector extends StatelessWidget {
  const _TaskSelector();

  @override
  Widget build(BuildContext context) {
    final selected = context.select((PomodoroBloc b) => b.state.selectedTask);
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.task_alt),
        title: Text(selected?.title ?? 'Chọn công việc để tập trung'),
        subtitle: selected != null ? Text(selected.type.label) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final result = await TaskPickerSheet.show(context);
          if (context.mounted) {
            // result == null nghĩa là chọn "không gắn task" hoặc đóng sheet.
            context.read<PomodoroBloc>().add(PomodoroTaskSelected(result));
          }
        },
        // Long-press để bỏ chọn nhanh.
        onLongPress: () => context
            .read<PomodoroBloc>()
            .add(const PomodoroTaskSelected(null)),
        textColor: theme.colorScheme.onSurface,
      ),
    );
  }
}

/// Hiển thị 3 giai đoạn dưới dạng chip, làm nổi bật giai đoạn hiện tại.
class _PhaseChips extends StatelessWidget {
  const _PhaseChips();

  @override
  Widget build(BuildContext context) {
    final phase = context.select((PomodoroBloc b) => b.state.phase);
    return Wrap(
      spacing: 8,
      children: PomodoroPhase.values.map((p) {
        final selected = p == phase;
        return ChoiceChip(
          label: Text(p.label),
          selected: selected,
          onSelected: null, // chỉ hiển thị, không cho đổi trực tiếp
        );
      }).toList(),
    );
  }
}

/// Vòng tròn tiến trình + thời gian đếm ngược ở giữa.
class _TimerRing extends StatelessWidget {
  const _TimerRing();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<PomodoroBloc>().state;

    final minutes =
        (state.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds =
        (state.remainingSeconds % 60).toString().padLeft(2, '0');

    // Màu vòng đổi theo giai đoạn: focus = primary, nghỉ = tertiary.
    final ringColor = state.phase == PomodoroPhase.focus
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;

    return ProgressRing(
      progress: state.progress,
      color: ringColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$minutes:$seconds',
              style: theme.textTheme.displayMedium
                  ?.copyWith(fontFeatures: const [])),
          const SizedBox(height: 4),
          Text(state.phase.label, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// Các nút điều khiển: bắt đầu/tạm dừng/tiếp tục, đặt lại, bỏ qua.
class _Controls extends StatelessWidget {
  const _Controls();

  @override
  Widget build(BuildContext context) {
    final status = context.select((PomodoroBloc b) => b.state.status);
    final bloc = context.read<PomodoroBloc>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Nút đặt lại (ẩn khi chưa chạy).
        if (status != TimerStatus.initial)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filledTonal(
              iconSize: 28,
              icon: const Icon(Icons.replay),
              tooltip: 'Đặt lại',
              onPressed: () => bloc.add(const PomodoroReset()),
            ),
          ),
        // Nút chính: play / pause / resume.
        _mainButton(context, status, bloc),
        // Nút bỏ qua giai đoạn.
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton.filledTonal(
            iconSize: 28,
            icon: const Icon(Icons.skip_next),
            tooltip: 'Bỏ qua giai đoạn',
            onPressed: () => bloc.add(const PomodoroSkipped()),
          ),
        ),
      ],
    );
  }

  Widget _mainButton(
      BuildContext context, TimerStatus status, PomodoroBloc bloc) {
    late final IconData icon;
    late final VoidCallback onPressed;
    switch (status) {
      case TimerStatus.initial:
      case TimerStatus.completed:
        icon = Icons.play_arrow;
        onPressed = () => bloc.add(const PomodoroStarted());
        break;
      case TimerStatus.running:
        icon = Icons.pause;
        onPressed = () => bloc.add(const PomodoroPaused());
        break;
      case TimerStatus.paused:
        icon = Icons.play_arrow;
        onPressed = () => bloc.add(const PomodoroResumed());
        break;
    }
    return FloatingActionButton.large(
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}

/// Hiển thị số phiên focus đã hoàn tất trong chu kỳ.
class _SessionCounter extends StatelessWidget {
  const _SessionCounter();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PomodoroBloc>().state;
    final total = state.config.sessionsBeforeLongBreak;
    final done = state.completedFocusSessions % total;
    return Column(
      children: [
        Text('Phiên tập trung: ${state.completedFocusSessions}',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final filled = i < done;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                filled ? Icons.circle : Icons.circle_outlined,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Hàng nút phụ: chỉnh thời lượng + xem thống kê.
class _BottomActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.tune),
          label: const Text('Thời lượng'),
          onPressed: () => _openConfig(context),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          icon: const Icon(Icons.bar_chart),
          label: const Text('Thống kê'),
          onPressed: () {
            // Truyền repository sẵn có xuống màn hình thống kê.
            final repo = context.read<FocusRepository>();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FocusStatsScreen(repository: repo),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openConfig(BuildContext context) async {
    final bloc = context.read<PomodoroBloc>();
    final current = bloc.state.config;
    final newConfig = await showDialog<PomodoroConfig>(
      context: context,
      builder: (_) => _ConfigDialog(config: current),
    );
    if (newConfig != null) {
      bloc.add(PomodoroConfigChanged(newConfig));
    }
  }
}

/// Dialog chỉnh thời lượng focus/nghỉ ngắn/nghỉ dài.
class _ConfigDialog extends StatefulWidget {
  const _ConfigDialog({required this.config});
  final PomodoroConfig config;

  @override
  State<_ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<_ConfigDialog> {
  late int _focus = widget.config.focusMinutes;
  late int _short = widget.config.shortBreakMinutes;
  late int _long = widget.config.longBreakMinutes;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thời lượng (phút)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepper('Tập trung', _focus, 5, 90, (v) => setState(() => _focus = v)),
          _stepper('Nghỉ ngắn', _short, 1, 30, (v) => setState(() => _short = v)),
          _stepper('Nghỉ dài', _long, 5, 60, (v) => setState(() => _long = v)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            widget.config.copyWith(
              focusMinutes: _focus,
              shortBreakMinutes: _short,
              longBreakMinutes: _long,
            ),
          ),
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  Widget _stepper(
      String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Text('$value', textAlign: TextAlign.center),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
