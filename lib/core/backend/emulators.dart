/// Où se trouve le backend, vu du téléphone.
///
/// Dans son propre fichier parce que le téléverseur et le démarrage en ont
/// besoin tous les deux, et qu'ils s'importent déjà dans un sens.
library;

/// Run against the local Firebase emulators instead of the real project.
///
///     flutter run --dart-define=USE_EMULATORS=true
///
/// This is how the whole workflow can be exercised end to end: reports really
/// are written, really get a reference number, and really come back on the
/// tracking screen — in a database that lives on this machine. No billing
/// account, no App Check registration, nothing to clean up afterwards.
///
/// A `const` from the environment rather than a runtime flag, so a release
/// build cannot be talked into pointing at a developer's laptop.
const bool useEmulators = bool.fromEnvironment('USE_EMULATORS');

/// Where the emulators are, seen from the device.
///
/// `10.0.2.2` is a **property of the Android emulator (AVD)**, not a general
/// convention: that emulator rewrites the address to the host's loopback.
/// `localhost` there would mean the emulated phone itself.
///
/// Anything else — a physical device, or one of the phone-preview extensions
/// that render a Flutter app without an AVD underneath — does not perform that
/// rewrite, and the host is simply unreachable. Pass the machine's address on
/// the local network instead:
///
///     --dart-define=EMULATOR_HOST=192.168.1.24
const String emulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: '10.0.2.2',
);

/// Rewrites a loopback address the backend handed out into one this device can
/// actually reach.
///
/// The function that issues an upload URL sees the emulator on `127.0.0.1`,
/// because that is where it sits. The phone does not: there, `127.0.0.1` is the
/// phone. A URL is only useful at the address of whoever will call it, and the
/// only side that knows how this device reaches the host is this device.
///
/// Outside emulator mode the URL is signed by Cloud Storage and left untouched.
String reachableFromDevice(String url) {
  if (!useEmulators) return url;
  final parsed = Uri.tryParse(url);
  if (parsed == null) return url;
  if (parsed.host != '127.0.0.1' && parsed.host != 'localhost') return url;
  return parsed.replace(host: emulatorHost).toString();
}
