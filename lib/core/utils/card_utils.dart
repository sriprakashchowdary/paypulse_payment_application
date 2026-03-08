import 'package:flutter/material.dart';
import '../../models/card_model.dart';

class CardUtils {
  static CardNetwork getCardNetwork(String cardNumber) {
    final sanitized = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (sanitized.isEmpty) {
      return CardNetwork.unknown;
    }

    if (sanitized.startsWith('4')) {
      return CardNetwork.visa;
    }

    if (_isMastercard(sanitized)) {
      return CardNetwork.mastercard;
    }

    if (sanitized.startsWith('34') || sanitized.startsWith('37')) {
      return CardNetwork.amex;
    }

    if (_isRupay(sanitized)) {
      return CardNetwork.rupay;
    }

    if (_isDiscover(sanitized)) {
      return CardNetwork.discover;
    }

    return CardNetwork.unknown;
  }

  static bool _isMastercard(String number) {
    if (number.startsWith(RegExp(r'5[1-5]'))) {
      return true;
    }

    if (number.length < 4) {
      return false;
    }

    final firstFour = int.tryParse(number.substring(0, 4));
    return firstFour != null && firstFour >= 2221 && firstFour <= 2720;
  }

  static bool _isDiscover(String number) {
    if (number.startsWith('6011')) {
      return true;
    }

    if (number.startsWith('65')) {
      return true;
    }

    if (number.length >= 3) {
      final firstThree = int.tryParse(number.substring(0, 3));
      if (firstThree != null && firstThree >= 644 && firstThree <= 649) {
        return true;
      }
    }

    if (number.length >= 6) {
      final firstSix = int.tryParse(number.substring(0, 6));
      if (firstSix != null && firstSix >= 622126 && firstSix <= 622925) {
        return true;
      }
    }

    return false;
  }

  static bool _isRupay(String number) {
    if (number.startsWith('508') ||
        number.startsWith('81') ||
        number.startsWith('82') ||
        number.startsWith('353') ||
        number.startsWith('356') ||
        number.startsWith('6521') ||
        number.startsWith('6522')) {
      return true;
    }

    if (number.startsWith('60') && !number.startsWith('6011')) {
      return true;
    }

    return false;
  }

  static String formatCardNumber(String input) {
    input = input.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      buffer.write(input[i]);
      final index = i + 1;
      if (index % 4 == 0 && index != input.length) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  static String formatExpiryDate(String input) {
    input = input.replaceAll(RegExp(r'\D'), '');
    if (input.length > 2) {
      return '${input.substring(0, 2)}/${input.substring(2, input.length.clamp(2, 4))}';
    }
    return input;
  }

  static IconData getNetworkIcon(CardNetwork network) {
    switch (network) {
      case CardNetwork.visa:
        return Icons.credit_card_rounded; // Would use brand icons in production
      case CardNetwork.mastercard:
        return Icons.payments_rounded;
      case CardNetwork.amex:
        return Icons.credit_score_rounded;
      case CardNetwork.discover:
        return Icons.style_rounded;
      case CardNetwork.rupay:
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
