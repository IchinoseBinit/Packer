/// Holds the base data for a CallKeep event
///
/// This is used as base for all callkeep event's data
class CallKeepBaseEvent {
  /// A unique UUID identifier for each call
  /// and when the call is ended, the same UUID for that call to be used.
  final String uuid;

  CallKeepBaseEvent({required this.uuid});
}
