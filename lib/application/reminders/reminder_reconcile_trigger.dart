// Hook để repository yêu cầu reconcile nhắc nhở sau khi ghi (Phase R, D11).

abstract class ReminderReconcileTrigger {
  /// Yêu cầu reconcile tăng dần. [alsoCancel] là các id có thể đã được đặt
  /// cho thực thể cũ/đã xóa (xem candidate helpers trong reminder_ids.dart).
  Future<void> requestReconcile({Iterable<int> alsoCancel = const []});
}

class NoOpReminderReconcileTrigger implements ReminderReconcileTrigger {
  const NoOpReminderReconcileTrigger();
  @override
  Future<void> requestReconcile({Iterable<int> alsoCancel = const []}) async {}
}
