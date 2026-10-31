/// Daily Review & Adaptive Rescheduling — deterministic core (Phase DR1).
///
/// Pure application layer: no Flutter UI, no sqflite, no notification
/// plugins. Flow: [DailyReviewService.review] → [ReschedulePlanner.plan] →
/// [ProposalApplier.apply] (confirmation required, re-validated per item).
library;

export 'availability.dart';
export 'daily_review_service.dart';
export 'daily_review_settings.dart';
export 'proposal_applier.dart';
export 'reschedule_planner.dart';
export 'reschedule_proposal.dart';
export 'review_snapshot.dart';
