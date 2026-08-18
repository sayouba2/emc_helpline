import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../utils/reference_code.dart';

/// Being told when a case moves, without telling anyone else anything.
///
/// This is the one part of the app that appears **without being asked for**, on
/// a lock screen, in front of whoever is holding the phone. The app is used by
/// children who often share a device, sometimes with the person they are
/// reporting. So three rules shape all of this:
///
/// - **Off unless explicitly turned on.** No permission prompt on launch, no
///   default subscription. The screen that offers it says plainly what a
///   notification would look like to someone else holding the phone.
/// - **No device is registered against a case.** Subscription is to an FCM
///   topic derived from the reference code; the server never learns which
///   devices are listening, and stores no token beside a report. The link
///   between this phone and this case exists only on this phone.
/// - **One switch turns everything off.** [disableAll] discards the FCM token,
///   which drops every topic this device was subscribed to at once — without
///   the app ever having written down which ones they were.
class CaseNotifications {
  CaseNotifications({
    Future<bool> Function()? requestPermission,
    Future<void> Function(String topic)? subscribe,
    Future<void> Function()? discardToken,
  }) : _requestPermission = requestPermission ?? _askTheSystem,
       _subscribe = subscribe ?? _subscribeToTopic,
       _discardToken = discardToken ?? _deleteToken;

  final Future<bool> Function() _requestPermission;
  final Future<void> Function(String topic) _subscribe;
  final Future<void> Function() _discardToken;

  /// Must match `topicFor` in `functions/src/notifications.ts`: the server
  /// publishes to a name it derives the same way, from the same hash the
  /// reference index is keyed on.
  ///
  /// The code itself never appears in the topic name — a hash of it does, so
  /// nothing recoverable travels to Google's servers as a subscription
  /// identifier.
  static String? topicFor(String referenceCode, String languageCode) {
    final payload = ReferenceCode.payloadOf(referenceCode);
    if (payload == null) return null;
    final hash = sha256.convert(utf8.encode(payload));
    return 'case_${hash}_$languageCode';
  }

  /// Asks the system, then subscribes. Returns false if permission was refused
  /// — the caller leaves the offer visible rather than pretending it worked.
  Future<bool> enableFor(String referenceCode, String languageCode) async {
    final topic = topicFor(referenceCode, languageCode);
    if (topic == null) return false;

    if (!await _requestPermission()) return false;

    await _subscribe(topic);
    return true;
  }

  /// Stops every notification this device could receive.
  ///
  /// Discarding the token rather than unsubscribing topic by topic is what lets
  /// the app forget the codes immediately: it never has to keep a list of what
  /// it subscribed to in order to be able to undo it.
  Future<void> disableAll() => _discardToken();

  static Future<bool> _askTheSystem() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  static Future<void> _subscribeToTopic(String topic) =>
      FirebaseMessaging.instance.subscribeToTopic(topic);

  static Future<void> _deleteToken() =>
      FirebaseMessaging.instance.deleteToken();
}
