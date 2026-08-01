import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class LauncherUtils {
  static Future<bool> makePhoneCall(String phoneNumber) async {
    try {
      final Uri url = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(url)) {
        return await launchUrl(url);
      }
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching phone call to $phoneNumber: $e');
      return false;
    }
  }

  static Future<bool> openWhatsApp(String phoneNumber, {String? message}) async {
    try {
      final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      final String encodedMsg = Uri.encodeComponent(message ?? "Bonjour, j'ai besoin d'assistance via EMC Helpline.");
      final Uri url = Uri.parse('https://wa.me/$cleanNumber?text=$encodedMsg');
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      return false;
    }
  }

  static Future<bool> sendEmail(String email, {String? subject, String? body}) async {
    try {
      final Map<String, String> queryParams = {};
      if (subject != null) queryParams['subject'] = subject;
      if (body != null) queryParams['body'] = body;

      final Uri url = Uri(
        scheme: 'mailto',
        path: email,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (await canLaunchUrl(url)) {
        return await launchUrl(url);
      }
      return false;
    } catch (e) {
      debugPrint('Error launching email to $email: $e');
      return false;
    }
  }

  static Future<bool> openWebPage(String urlString) async {
    try {
      String formattedUrl = urlString;
      if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }
      final Uri url = Uri.parse(formattedUrl);
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('Error launching web page $urlString: $e');
      return false;
    }
  }
}
