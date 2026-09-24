import 'package:flutter/foundation.dart';

import 'package:packer/features/views/shift_clock/models/shift_refusal.dart';

/// The last time the roster sign-in gate turned this phone away, for the login
/// screen to show; null for nothing to show, which with the gate off is always.
///
/// Set by DioClient's 403 branch wherever the refusal came from - the sign-in
/// itself, a token refresh, or a request made after the clock checked the
/// person out, when there is no screen of theirs left to show it on. The login
/// screen keeps it up until the next sign-in attempt: it may have been someone
/// else's.
final signInRefusal = ValueNotifier<ShiftRefusal?>(null);
