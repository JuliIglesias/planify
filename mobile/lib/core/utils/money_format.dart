import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MoneyFormat {
  static final _formatter = NumberFormat.currency(
    locale: 'es_ES', // Usa punto para miles y coma para decimales
    symbol: '',
  );

  /// Toma un valor crudo (ej: '5666.99' o '5666,99' o un entero)
  /// y lo formatea como '5.666,99'
  static String format(String? amount) {
    if (amount == null || amount.isEmpty) return '0,00';
    final parsed = parse(amount);
    return _formatter.format(parsed).trim();
  }

  /// Parsea un string que puede tener formato ('5.666,99') o ser crudo ('5666.99')
  /// y devuelve el valor como double.
  static double parse(String formatted) {
    if (formatted.isEmpty) return 0.0;
    // Si tiene comas y puntos, asumimos que el punto es de miles (es_ES)
    // Primero removemos el punto de miles, luego cambiamos la coma por punto.
    String clean = formatted;
    // Si la cadena ya viene del backend como '5666.99' (sin comas), parse normal
    if (clean.contains('.') && !clean.contains(',')) {
      return double.tryParse(clean) ?? 0.0;
    }
    // Si tiene comas, es posible que sea el input del usuario '5.666,99'
    clean = clean.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(clean) ?? 0.0;
  }
}

class EuroMoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remover todo lo que no sea dígito o coma
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9,]'), '');
    
    // Asegurar que solo haya una coma
    final parts = cleanText.split(',');
    if (parts.length > 2) {
      cleanText = '${parts[0]},${parts.sublist(1).join('')}';
    }

    // Limitar a 2 decimales
    if (cleanText.contains(',')) {
      final p = cleanText.split(',');
      if (p[1].length > 2) {
        cleanText = '${p[0]},${p[1].substring(0, 2)}';
      }
    }

    // Formatear miles con punto
    String formatted = '';
    final finalParts = cleanText.split(',');
    String integerPart = finalParts[0];
    
    // Si el usuario borró todo y quedó solo una coma
    if (integerPart.isEmpty && finalParts.length > 1) {
      integerPart = '0';
    }

    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = '.$formatted';
      }
      formatted = '${integerPart[i]}$formatted';
      count++;
    }

    if (finalParts.length > 1) {
      formatted = '$formatted,${finalParts[1]}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
