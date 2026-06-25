import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_order_model.dart';

/// Siparis durum zaman cizgisi.
/// Genis ekranda yatay, dar ekranda dikey gosterilir.
class OrderTimeline extends StatelessWidget {
  final AdminOrderStatus currentStatus;
  final AdminOrderModel order;

  const OrderTimeline({
    super.key,
    required this.currentStatus,
    required this.order,
  });

  // Timeline sadece ana akis adimlarini gosterir (cancel/refund hariç)
  static const List<_TimelineStep> _kSteps = [
    _TimelineStep(
      status: AdminOrderStatus.pending,
      label: 'Olusturuldu',
      icon: Icons.receipt_outlined,
    ),
    _TimelineStep(
      status: AdminOrderStatus.confirmed,
      label: 'Onaylandi',
      icon: Icons.check_circle_outline,
    ),
    _TimelineStep(
      status: AdminOrderStatus.preparing,
      label: 'Hazirlaniyor',
      icon: Icons.restaurant_outlined,
    ),
    _TimelineStep(
      status: AdminOrderStatus.onTheWay,
      label: 'Yolda',
      icon: Icons.local_shipping_outlined,
    ),
    _TimelineStep(
      status: AdminOrderStatus.delivered,
      label: 'Teslim Edildi',
      icon: Icons.done_all,
    ),
  ];

  DateTime? _dateForStatus(AdminOrderStatus s) {
    return switch (s) {
      AdminOrderStatus.pending => order.createdAt,
      AdminOrderStatus.confirmed => order.confirmedAt,
      AdminOrderStatus.preparing => order.preparingAt,
      AdminOrderStatus.onTheWay => order.onTheWayAt,
      AdminOrderStatus.delivered => order.deliveredAt,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;

    // İptal veya iade durumunda özel gösterim
    if (currentStatus == AdminOrderStatus.cancelled ||
        currentStatus == AdminOrderStatus.refunded) {
      return _CancelledBadge(status: currentStatus);
    }

    if (isWide) {
      return _HorizontalTimeline(
        steps: _kSteps,
        currentStatus: currentStatus,
        dateForStatus: _dateForStatus,
      );
    }
    return _VerticalTimeline(
      steps: _kSteps,
      currentStatus: currentStatus,
      dateForStatus: _dateForStatus,
    );
  }
}

// ---------------------------------------------------------------------------
// Iptal / iade badge
// ---------------------------------------------------------------------------
class _CancelledBadge extends StatelessWidget {
  final AdminOrderStatus status;
  const _CancelledBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(status.icon, color: status.color, size: 20),
          const SizedBox(width: 10),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Yatay timeline (desktop / tablet)
// ---------------------------------------------------------------------------
class _HorizontalTimeline extends StatelessWidget {
  final List<_TimelineStep> steps;
  final AdminOrderStatus currentStatus;
  final DateTime? Function(AdminOrderStatus) dateForStatus;

  const _HorizontalTimeline({
    required this.steps,
    required this.currentStatus,
    required this.dateForStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length * 2 - 1, (i) {
        // Cizgi
        if (i.isOdd) {
          final leftStepIndex = i ~/ 2;
          final leftStatus = steps[leftStepIndex].status;
          final isDone = currentStatus.index > leftStatus.index;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                height: 2,
                color: isDone
                    ? AppColors.success
                    : AppColors.border,
              ),
            ),
          );
        }
        // Adim
        final stepIndex = i ~/ 2;
        final step = steps[stepIndex];
        final stepState = _getStepState(step.status);
        final date = dateForStatus(step.status);
        return _HorizontalStepNode(
          step: step,
          state: stepState,
          date: date,
        );
      }),
    );
  }

  _StepState _getStepState(AdminOrderStatus s) {
    if (currentStatus == s) return _StepState.active;
    if (currentStatus.index > s.index) return _StepState.done;
    return _StepState.future;
  }
}

class _HorizontalStepNode extends StatelessWidget {
  final _TimelineStep step;
  final _StepState state;
  final DateTime? date;

  const _HorizontalStepNode({
    required this.step,
    required this.state,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.done => AppColors.success,
      _StepState.active => AppColors.primary,
      _StepState.future => AppColors.border,
    };
    final textColor = switch (state) {
      _StepState.done => AppColors.success,
      _StepState.active => AppColors.primary,
      _StepState.future => AppColors.textHint,
    };

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: state == _StepState.future
                ? AppColors.surface
                : color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: state == _StepState.active ? 2 : 1.5),
          ),
          child: Icon(
            state == _StepState.done ? Icons.check : step.icon,
            size: 16,
            color: state == _StepState.future ? AppColors.textHint : color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          step.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: state == _StepState.active
                ? FontWeight.w600
                : FontWeight.w400,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
        if (date != null) ...[
          const SizedBox(height: 2),
          Text(
            DateFormat('dd/MM HH:mm').format(date!),
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dikey timeline (mobil)
// ---------------------------------------------------------------------------
class _VerticalTimeline extends StatelessWidget {
  final List<_TimelineStep> steps;
  final AdminOrderStatus currentStatus;
  final DateTime? Function(AdminOrderStatus) dateForStatus;

  const _VerticalTimeline({
    required this.steps,
    required this.currentStatus,
    required this.dateForStatus,
  });

  _StepState _getStepState(AdminOrderStatus s) {
    if (currentStatus == s) return _StepState.active;
    if (currentStatus.index > s.index) return _StepState.done;
    return _StepState.future;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final stepState = _getStepState(step.status);
        final date = dateForStatus(step.status);
        final isLast = i == steps.length - 1;

        return _VerticalStepRow(
          step: step,
          state: stepState,
          date: date,
          isLast: isLast,
        );
      }),
    );
  }
}

class _VerticalStepRow extends StatelessWidget {
  final _TimelineStep step;
  final _StepState state;
  final DateTime? date;
  final bool isLast;

  const _VerticalStepRow({
    required this.step,
    required this.state,
    required this.isLast,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.done => AppColors.success,
      _StepState.active => AppColors.primary,
      _StepState.future => AppColors.border,
    };
    final textColor = switch (state) {
      _StepState.done => AppColors.success,
      _StepState.active => AppColors.primary,
      _StepState.future => AppColors.textHint,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sol: daire + cizgi
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: state == _StepState.future
                        ? AppColors.surface
                        : color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: color, width: state == _StepState.active ? 2 : 1.5),
                  ),
                  child: Icon(
                    state == _StepState.done ? Icons.check : step.icon,
                    size: 15,
                    color: state == _StepState.future ? AppColors.textHint : color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: state == _StepState.done
                          ? AppColors.success
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          // Sag: metin + tarih
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: 10,
                bottom: isLast ? 0 : 12,
                top: 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: state == _StepState.active
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                  if (date != null)
                    Text(
                      DateFormat('dd MMMM HH:mm', 'tr_TR').format(date!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Yardimci tipler
// ---------------------------------------------------------------------------
enum _StepState { done, active, future }

class _TimelineStep {
  final AdminOrderStatus status;
  final String label;
  final IconData icon;

  const _TimelineStep({
    required this.status,
    required this.label,
    required this.icon,
  });
}
