import 'dart:convert';

/// Client-side data model representing a shortened link record
class ShortLinkRecord {
  final String linkId;
  final String userId;
  final String userEmail;
  final String shortCode;
  final String destinationUrl;
  final String fallbackUrl;
  final DateTime? expiresAt;
  final bool isActive;
  final int clickCount;
  final DateTime? lastClickedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? qrConfigJson;

  ShortLinkRecord({
    required this.linkId,
    required this.userId,
    required this.userEmail,
    required this.shortCode,
    required this.destinationUrl,
    this.fallbackUrl = 'https://rice.edu',
    this.expiresAt,
    this.isActive = true,
    this.clickCount = 0,
    this.lastClickedAt,
    required this.createdAt,
    required this.updatedAt,
    this.qrConfigJson,
  });

  factory ShortLinkRecord.fromJson(Map<String, dynamic> json) {
    return ShortLinkRecord(
      linkId: json['id'] ?? json['linkId'] ?? '',
      userId: json['userId'] ?? '',
      userEmail: json['userEmail'] ?? '',
      shortCode: json['shortCode'] ?? '',
      destinationUrl: json['destinationUrl'] ?? '',
      fallbackUrl: json['fallbackUrl'] ?? 'https://rice.edu',
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt']) : null,
      isActive: json['isActive'] ?? true,
      clickCount: (json['clickCount'] as num?)?.toInt() ?? 0,
      lastClickedAt: json['lastClickedAt'] != null ? DateTime.tryParse(json['lastClickedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      qrConfigJson: json['qrConfigJson'] is String
          ? json['qrConfigJson'] as String
          : (json['qrConfig'] != null
              ? (json['qrConfig'] is String
                  ? json['qrConfig'] as String
                  : jsonEncode(json['qrConfig']))
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': linkId,
      'linkId': linkId,
      'userId': userId,
      'userEmail': userEmail,
      'shortCode': shortCode,
      'destinationUrl': destinationUrl,
      'fallbackUrl': fallbackUrl,
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'clickCount': clickCount,
      'lastClickedAt': lastClickedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'qrConfigJson': qrConfigJson,
    };
  }
}

