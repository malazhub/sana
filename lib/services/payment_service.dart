import 'package:url_launcher/url_launcher_string.dart';

class PaymentService {
  /// Opens the provided payment URL in the browser.
  /// Returns true if the URL was launched.
  static Future<bool> openPaymentUrl(String url) async {
    try {
      final launched =
          await launchUrlString(url, mode: LaunchMode.externalApplication);
      return launched;
    } catch (_) {
      return false;
    }
  }
}
