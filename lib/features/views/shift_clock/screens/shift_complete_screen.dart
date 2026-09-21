import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/audit_product/utils/start_stock_audit.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/profile/utils/packer_logout.dart';
import 'package:packer/features/views/shift_clock/models/shift_session.dart';
import 'package:packer/features/views/shift_clock/providers/shift_clock_provider.dart';
import 'package:packer/features/views/shift_clock/utils/shift_clock_logic.dart';
import 'package:packer/features/views/shift_clock/utils/shift_clock_route_observer.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';

/// Full-screen "Your shift is complete", up while the clock says show_dialog
/// and the packer or driver has nothing in hand. A packer still packing an
/// order or a basket never sees it: they read "Shift over · finish this order"
/// on the home screen, and this opens once that work is done. A driver with a
/// transfer packed for them or on the road reads "Shift over · deliver this
/// transfer" the same way.
///
/// Back does not leave it. It closes itself when the shift clock stops asking
/// for it: an extension is approved, work lands in their hands, or they are
/// checked out. A dark-store packer who still owes this shift's stock audit
/// can start or continue it from here: the audit opens on top and going back
/// from it returns here, ready to check out. A driver owes no audit and is
/// never offered one.
class ShiftCompleteScreen extends StatefulWidget {
  const ShiftCompleteScreen({super.key});

  @override
  State<ShiftCompleteScreen> createState() => _ShiftCompleteScreenState();
}

class _ShiftCompleteScreenState extends State<ShiftCompleteScreen> {
  late final ShiftClockProvider _clock;
  final _reasonController = TextEditingController();
  ModalRoute<dynamic>? _route;
  late double _hours;
  bool _canPop = false;
  bool _closeRequested = false;
  bool _checkingOut = false;
  bool _openingAudit = false;

  @override
  void initState() {
    super.initState();
    _clock = context.read<ShiftClockProvider>();
    _clock.attachScreen(_requestClose);
    shiftClockRouteObserver.top.addListener(_onTopRouteChanged);
    final roster = _clock.state?.roster;
    _hours = defaultExtensionHours(roster);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_clock.wantsScreen) _requestClose();
      // Current stock audit status, for the audit prompt (a packer's only).
      if (_clock.isPacker) context.read<HomeProvider>().fetchpackerSummary();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  @override
  void dispose() {
    _clock.detachScreen(_requestClose);
    shiftClockRouteObserver.top.removeListener(_onTopRouteChanged);
    _reasonController.dispose();
    super.dispose();
  }

  void _requestClose() {
    _closeRequested = true;
    _tryClose();
  }

  void _onTopRouteChanged() {
    if (!_closeRequested) return;
    // Runs while the navigator is updating; act once the frame is done.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryClose());
  }

  void _tryClose() {
    if (!mounted || !_closeRequested || _checkingOut || _canPop) return;
    if (_clock.wantsScreen) {
      _closeRequested = false;
      return;
    }
    // The check-out scanner or a dialog is on top: close once it is gone.
    if (_route != null && !_route!.isCurrent) return;
    _closeRequested = false;
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Something (the stock audit, a dialog) was pushed on top in the
      // meantime: pop() would close that instead. Close once it is gone.
      if (_route != null && !_route!.isCurrent) {
        _closeRequested = true;
        setState(() => _canPop = false);
        return;
      }
      Navigator.of(context).pop();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final sent = await _clock.requestExtension(
      hours: _hours,
      reason: _reasonController.text.trim(),
    );
    if (sent && mounted) _reasonController.clear();
  }

  /// Starts this shift's stock audit (after the app's usual confirmation) or
  /// opens the one in progress, on top of this screen.
  Future<void> _openAudit() async {
    if (_openingAudit || _checkingOut) return;
    setState(() => _openingAudit = true);
    try {
      await startStockAudit(context);
    } finally {
      if (mounted) setState(() => _openingAudit = false);
    }
  }

  Future<void> _checkOut() async {
    if (_checkingOut || _openingAudit) return;
    setState(() => _checkingOut = true);
    try {
      await logoutWithCheckout(context);
    } finally {
      if (mounted) {
        setState(() => _checkingOut = false);
        _tryClose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: SafeArea(
          child: Consumer2<ShiftClockProvider, HomeProvider>(
              builder: (context, clock, home, _) {
            final session = clock.state;
            if (session == null || !session.hasSession) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            final now = DateTime.now();
            // The stock audit hand-off is a packer's. A driver on a dark
            // store's books still gets an audit_status in their summary (it
            // is worked out from the store, not the role), and it is not
            // theirs to start.
            final audit = clock.isPacker
                ? shiftAuditPrompt(home.packerSummary?.auditStatus)
                : null;
            return RefreshIndicator(
              onRefresh: () => Future.wait([
                clock.refresh(),
                if (clock.isPacker) home.fetchpackerSummary(),
              ]),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ..._header(session, now),
                    SizedBox(height: 16.h),
                    _ShiftNotice(
                      icon: Icons.event_note_outlined,
                      text: rosterLine(session.roster),
                      color: AppColors.blue500,
                    ),
                    _ShiftNotice(
                      icon: Icons.logout,
                      text: graceLine(session, now),
                      color: AppColors.primaryColor,
                    ),
                    if (session.note.isNotEmpty)
                      _ShiftNotice(
                        icon: Icons.info_outline,
                        text: session.note,
                        color: Colors.orange.shade800,
                      ),
                    if (audit != null) _auditCard(audit),
                    ..._requestSection(clock, session, now),
                    SizedBox(height: 24.h),
                    GeneralElevatedButton(
                      title: _checkingOut
                          ? 'Checking out...'
                          : 'Check out and log out',
                      isDisabled: _checkingOut || _openingAudit,
                      bgColor: Colors.white,
                      borderColor: AppColors.primaryColor,
                      textStyle: _textStyle(
                          15, FontWeight.w600, AppColors.primaryColor),
                      onPressed: _checkOut,
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  List<Widget> _header(ShiftSessionState session, DateTime now) {
    final started = session.startedAt;
    final ended = session.regularLimitAt;
    final serverNow = session.serverTimeAt(now);
    return [
      Icon(Icons.timer_off_outlined, size: 48.w, color: AppColors.primaryColor),
      SizedBox(height: 12.h),
      Text(
        'Your shift is complete',
        textAlign: TextAlign.center,
        style: _textStyle(22, FontWeight.w700, Colors.black),
      ),
      SizedBox(height: 16.h),
      Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            _timeRow(
              'You started',
              started == null ? '-' : formatShiftClockOn(started, serverNow),
            ),
            SizedBox(height: 8.h),
            _timeRow(
              'Regular hours ended',
              ended == null ? '-' : formatShiftClockOn(ended, serverNow),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _auditCard(ShiftAuditPrompt audit) {
    final color = Colors.orange.shade800;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.inventory_2_outlined, color: color, size: 22.w),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  audit.text,
                  style: _textStyle(14, FontWeight.w500, Colors.black87),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          GeneralElevatedButton(
            title: audit.button,
            isDisabled: _openingAudit || _checkingOut,
            bgColor: Colors.white,
            borderColor: color,
            height: 42.h,
            textStyle: _textStyle(14, FontWeight.w600, color),
            onPressed: _openAudit,
          ),
        ],
      ),
    );
  }

  Widget _timeRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: _textStyle(13, FontWeight.w400, Colors.black54)),
        ),
        Text(value, style: _textStyle(15, FontWeight.w600, Colors.black)),
      ],
    );
  }

  List<Widget> _requestSection(
      ShiftClockProvider clock, ShiftSessionState session, DateTime now) {
    final pending = session.pendingRequest;
    if (pending != null) return [_pendingCard(clock, session, pending, now)];

    final decision = session.lastDecision;
    final ended = extensionEndedLine(session, now: now);
    return [
      if (decision?.status == ShiftRequestStatus.rejected)
        _ShiftNotice(
          icon: Icons.block,
          text: rejectedRequestLine,
          detail: decision!.reviewNote.isEmpty ? null : decision.reviewNote,
          color: Colors.red.shade700,
        )
      else if (ended != null)
        _ShiftNotice(
          icon: Icons.history,
          text: ended,
          color: AppColors.homeScreenDimTextColor,
        ),
      if (session.canRequest) _requestForm(clock, session, now),
    ];
  }

  Widget _pendingCard(ShiftClockProvider clock, ShiftSessionState session,
      ShiftRequest pending, DateTime now) {
    final id = pending.id;
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.hourglass_top, color: AppColors.blue500, size: 22.w),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  pendingRequestLine(pending, session.serverTimeAt(now)),
                  style: _textStyle(14, FontWeight.w500, Colors.black87),
                ),
              ),
            ],
          ),
          if (pending.reason.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              'Your reason: ${pending.reason}',
              style: _textStyle(12, FontWeight.w400, Colors.black54),
            ),
          ],
          SizedBox(height: 12.h),
          GeneralElevatedButton(
            title: clock.isCancelling ? 'Cancelling...' : 'Cancel request',
            isDisabled: clock.isCancelling || id == null,
            bgColor: Colors.white,
            borderColor: AppColors.blue500,
            height: 42.h,
            textStyle: _textStyle(14, FontWeight.w600, AppColors.blue500),
            onPressed: () {
              if (id != null) clock.cancelRequest(id);
            },
          ),
        ],
      ),
    );
  }

  Widget _requestForm(
      ShiftClockProvider clock, ShiftSessionState session, DateTime now) {
    final until = estimateRequestedUntil(session, _hours, now);
    // The roster decides the pay; this only says which it is.
    final payLine = extraHoursPayLine(session.extraHoursPay);
    final busy = clock.isSubmitting;
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ask to keep working',
              style: _textStyle(16, FontWeight.w600, Colors.black)),
          SizedBox(height: 12.h),
          Text('How much more time?',
              style: _textStyle(13, FontWeight.w500, Colors.black87)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final hours in shiftExtensionHourChoices)
                _choice(
                  label: formatShiftHours(hours),
                  selected: _hours == hours,
                  onSelected: busy ? null : () => setState(() => _hours = hours),
                ),
            ],
          ),
          if (until != null) ...[
            SizedBox(height: 8.h),
            Text(
              "You'd work until about ${formatShiftClockOn(until, session.serverTimeAt(now))}",
              style: _textStyle(12, FontWeight.w400, Colors.black54),
            ),
          ],
          if (payLine != null) ...[
            SizedBox(height: 14.h),
            Text(payLine,
                style: _textStyle(13, FontWeight.w500, Colors.black87)),
          ],
          SizedBox(height: 14.h),
          TextField(
            controller: _reasonController,
            enabled: !busy,
            maxLines: 2,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            style: _textStyle(14, FontWeight.w400, Colors.black),
            decoration: InputDecoration(
              labelText: 'Reason (optional)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
            ),
          ),
          if (clock.requestError != null) ...[
            SizedBox(height: 4.h),
            Text(
              clock.requestError!,
              style: _textStyle(13, FontWeight.w500, Colors.red.shade700),
            ),
          ],
          SizedBox(height: 12.h),
          GeneralElevatedButton(
            title: busy ? 'Sending...' : 'Request extension',
            isDisabled: busy,
            textStyle: _textStyle(15, FontWeight.w600, Colors.white),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _choice({
    required String label,
    required bool selected,
    required VoidCallback? onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: onSelected == null ? null : (_) => onSelected(),
      selectedColor: AppColors.primaryColor,
      backgroundColor: Colors.white,
      labelStyle: _textStyle(
          13, FontWeight.w500, selected ? Colors.white : Colors.black87),
      side: BorderSide(
        color: selected ? AppColors.primaryColor : AppColors.borderColor,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

TextStyle _textStyle(double size, FontWeight weight, Color color) => TextStyle(
      fontFamily: 'Poppins',
      fontSize: size.sp,
      fontWeight: weight,
      color: color,
    );

class _ShiftNotice extends StatelessWidget {
  const _ShiftNotice({
    required this.icon,
    required this.text,
    required this.color,
    this.detail,
  });

  final IconData icon;
  final String text;
  final String? detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20.w),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text,
                      style: _textStyle(13, FontWeight.w500, Colors.black87)),
                  if (detail != null) ...[
                    SizedBox(height: 4.h),
                    Text(detail!,
                        style: _textStyle(12, FontWeight.w400, Colors.black54)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
