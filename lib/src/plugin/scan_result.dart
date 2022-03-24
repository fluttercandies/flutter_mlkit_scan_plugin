///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 12/11/20 4:31 PM
///
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'enums.dart';

@immutable
class ScanResult {
  const ScanResult({
    required this.state,
    this.code,
    this.phone = const <String>[],
  });

  factory ScanResult.fromJson(Map<dynamic, dynamic> json) {
    return ScanResult(
      state: json['state'] as int,
      code: json['code']?.toString(),
      phone: filterPhoneList(json),
    );
  }

  final int state;
  final String? code;
  final List<String> phone;

  static List<String> filterPhoneList(Map<dynamic, dynamic> json) {
    final String? code = json['code']?.toString();
    final Object? list = json['phone'];
    if (list == null || list is! List || list.isEmpty) {
      return <String>[];
    }
    final Iterable<String> notEmptyList =
        list.cast<String>().where((String e) => e.isNotEmpty);
    if (notEmptyList.isEmpty) {
      return <String>[];
    }
    // Obtain all phone numbers from the list.
    final Set<String> numbers = notEmptyList.fold(
      <String>{},
      (Set<String> p, String e) => p
        ..addAll(
          RegExp(r'1[3-9]\d{9}')
              .allMatches(e)
              .map((Match m) => m.group(0))
              .whereType<String>(),
        ),
    );
    if (code != null) {
      numbers.removeWhere(code.contains);
    }
    return numbers.toList();
  }

  ScanResultStatus get status => ScanResultStatus.from(state);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'state': state,
      if (code != null) 'code': code,
      'phone': phone,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResult &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          code == other.code &&
          phone == other.phone;

  @override
  int get hashCode => hashValues(state, code, phone);

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
