import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// checked out.
///
/// A visit ([ShiftClockProvider.visitingScreen]) - someone past the stop mark
/// with work still in hand, brought here by the countdown or by a tap on the
/// home status card - is blocking just the same: Back does not leave it
/// either. Both ways out are on the page whatever is in hand: ask support for
/// more time, or check out and log out - with a line saying what is still
/// open, since the server may refuse a check-out over it. Should the work
/// finish while they stand here, the visit turns into the clock's own screen. A dark-store packer who still owes this shift's stock audit
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
  late int _minutes;
  final _hoursField = TextEditingController();
  final _minutesField = TextEditingController();
  String? _spanProblem;
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
    _minutes = defaultExtensionMinutes(_clock.state);
    _writeSpanFields();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_clock.wantsScreen &&
          !_clock.showsApproval &&
          !_clock.visitingScreen) {
        _requestClose();
      }
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
    _hoursField.dispose();
    _minutesField.dispose();
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
    if (_clock.wantsScreen || _clock.showsApproval) {
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

  /// Put [_minutes] back into the two fields, so what is typed and what will
  /// be sent can never drift apart.
  void _writeSpanFields() {
    _hoursField.text = (_minutes ~/ 60).toString();
    _minutesField.text = (_minutes % 60).toString();
  }

  /// Read the two fields back into whole minutes. Empty reads as zero, so a
  /// half-filled form is simply a short one rather than an error.
  void _readSpanFields() {
    final hours = int.tryParse(_hoursField.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesField.text.trim()) ?? 0;
    setState(() {
      _minutes = (hours * 60) + minutes;
      _spanProblem = extensionSpanProblem(_minutes, _clock.state);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final problem = extensionSpanProblem(_minutes, _clock.state);
    if (problem != null) {
      setState(() => _spanProblem = problem);
      return;
    }
    final sent = await _clock.requestExtension(
      minutes: _minutes,
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
    // Nobody leaves this page by hand, however they got here - the clock put
    // them here because their time is up, and the system Back gesture, the
    // hardware button and any back arrow all stop at it. It goes only when the
    // clock itself says so (_requestClose sets _canPop): more time approved,
    // work back in hand, or checked out.
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
            //
            // Not while work is in hand either: a packer who came here to ask
            // for more time has an order to get back to, not an audit to start.
            // final held = shiftCheckoutHeldLine(clock.workInHand);
            final audit = clock.isPacker
                ? shiftAuditPrompt(home.packerSummary?.auditStatus)
                : null;
            final approved = clock.showsApproval;
            return RefreshIndicator(
              onRefresh: () => Future.wait([
                clock.refresh(),
                if (clock.isPacker) home.fetchpackerSummary(),
              ]),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                child: approved
                    ? _approvalBody(clock, session, now)
                    : Column(
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
                          ..._requestSection(clock, session, now,
                              auditOwed: audit != null),
                          SizedBox(height: 24.h),
                          // The audit comes first: the backend refuses the
                          // check out while it is owed anyway. One gate stands
                          // in for both this and the Request extension button.
                          if (audit != null)
                            _auditGate('Complete the stock audit to request '
                                'an extension or check out and log out.')
                          else
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

  /// Support said yes while they stood here: until when, and what to do next.
  ///
  /// The same page a tap on the approval notification lands on, and the one
  /// the refresh button leads to, so the answer reads the same however they
  /// arrive at it.
  Widget _approvalBody(
      ShiftClockProvider clock, ShiftSessionState session, DateTime now) {
    final until = session.hardLimitAt;
    final serverNow = session.serverTimeAt(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle_outline,
            size: 48.w, color: AppColors.primaryColor),
        SizedBox(height: 12.h),
        Text(
          until == null
              ? 'Support approved more time'
              : 'Extended until ${formatShiftClockOn(until, serverNow)}',
          textAlign: TextAlign.center,
          style: _textStyle(22, FontWeight.w700, Colors.black),
        ),
        SizedBox(height: 8.h),
        Text(
          'Check out of this shift and sign in again to work the extra time. '
          'It is recorded on its own, so the extra hours are paid as agreed.',
          textAlign: TextAlign.center,
          style: _textStyle(14, FontWeight.w400, Colors.black54),
        ),
        SizedBox(height: 24.h),
        // One way on: check out, then sign in again. That sign-in opens the
        // extension as a shift of its own, priced at the approved rate and
        // ending at the approved time (attendance.services.live_approval).
        // There is deliberately nothing here that carries on in place - the
        // stopped shift has to be closed for the extra time to be its own row.
        GeneralElevatedButton(
          title: _checkingOut ? 'Checking out...' : 'Check out and log out',
          isDisabled: _checkingOut,
          onPressed: _checkOut,
        ),
        SizedBox(height: 12.h),
      ],
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

  /// Stands in for a button the owed stock audit holds back; a tap opens the
  /// audit, and coming back from it finished brings the button back.
  Widget _auditGate(String text) {
    final color = Colors.orange.shade800;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openingAudit || _checkingOut ? null : _openAudit,
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: color, size: 22.w),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  text,
                  style: _textStyle(14, FontWeight.w500, Colors.black87),
                ),
              ),
              _openingAudit
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: color),
                    )
                  : Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
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
      ShiftClockProvider clock, ShiftSessionState session, DateTime now,
      {required bool auditOwed}) {
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
      if (extensionSpent(session))
        _ShiftNotice(
          icon: Icons.hourglass_disabled,
          text: 'You have already had '
              '${formatShiftMinutes(usedExtensionMinutes(session))} extra on this '
              'shift, which is all it allows.',
          detail: 'Check out, or ask support to check you out.',
          color: AppColors.primaryColor,
        ),
      if (session.canRequest)
        _requestForm(clock, session, now, auditOwed: auditOwed),
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
          // A button of their own, not only the pull down: this is the one
          // thing they are waiting on, and a notification may not arrive.
          GeneralElevatedButton(
            title: clock.isRefreshing ? 'Checking...' : 'Check for an answer',
            isDisabled: clock.isRefreshing || clock.isCancelling,
            bgColor: AppColors.blue500,
            borderColor: AppColors.blue500,
            height: 42.h,
            textStyle: _textStyle(14, FontWeight.w600, Colors.white),
            onPressed: clock.refresh,
          ),
          SizedBox(height: 8.h),
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
      ShiftClockProvider clock, ShiftSessionState session, DateTime now,
      {required bool auditOwed}) {
    final until = estimateRequestedUntil(session, _minutes, now);
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _spanField(
                  controller: _hoursField,
                  suffix: 'hours',
                  enabled: !busy,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _spanField(
                  controller: _minutesField,
                  suffix: 'minutes',
                  enabled: !busy,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            _spanProblem ?? extensionAllowanceLine(session),
            style: _textStyle(
              12,
              FontWeight.w400,
              _spanProblem == null ? Colors.black54 : Colors.red.shade700,
            ),
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
          // No asking for more time while this shift's stock audit is owed:
          // the one audit gate under this form says so and opens the audit.
          if (!auditOwed)
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

  /// One of the two number fields the span is typed into.
  Widget _spanField({
    required TextEditingController controller,
    required String suffix,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => _readSpanFields(),
      style: _textStyle(15, FontWeight.w500, Colors.black),
      decoration: InputDecoration(
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
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
