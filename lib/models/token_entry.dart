import 'package:flutter/foundation.dart';

enum OtpAlgorithm { sha1, sha256, sha512 }

@immutable
class TokenEntry {
  const TokenEntry({
    required this.id,
    required this.issuer,
    required this.account,
    required this.secretBase32,
    required this.digits,
    required this.periodSeconds,
    required this.algorithm,
    required this.createdAt,
  });

  final String id;
  final String issuer;
  final String account;
  final String secretBase32;
  final int digits;
  final int periodSeconds;
  final OtpAlgorithm algorithm;
  final DateTime createdAt;

  TokenEntry copyWith({
    String? id,
    String? issuer,
    String? account,
    String? secretBase32,
    int? digits,
    int? periodSeconds,
    OtpAlgorithm? algorithm,
    DateTime? createdAt,
  }) {
    return TokenEntry(
      id: id ?? this.id,
      issuer: issuer ?? this.issuer,
      account: account ?? this.account,
      secretBase32: secretBase32 ?? this.secretBase32,
      digits: digits ?? this.digits,
      periodSeconds: periodSeconds ?? this.periodSeconds,
      algorithm: algorithm ?? this.algorithm,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'issuer': issuer,
        'account': account,
        'secretBase32': secretBase32,
        'digits': digits,
        'periodSeconds': periodSeconds,
        'algorithm': algorithm.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TokenEntry.fromJson(Map<String, dynamic> json) {
    return TokenEntry(
      id: json['id'] as String,
      issuer: json['issuer'] as String,
      account: json['account'] as String,
      secretBase32: json['secretBase32'] as String,
      digits: json['digits'] as int,
      periodSeconds: json['periodSeconds'] as int,
      algorithm: OtpAlgorithm.values.firstWhere(
        (value) => value.name == json['algorithm'],
        orElse: () => OtpAlgorithm.sha1,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
