import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import 'qr_config.dart';

class ShortLink {
  final String id;
  final String userId;
  final String userEmail;
  final String shortCode;
  final String destinationUrl;
  final String fallbackUrl;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final QrConfig qrConfig;
  final int clickCount;
  final DateTime? lastClickedAt;

  const ShortLink({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.shortCode,
    required this.destinationUrl,
    this.fallbackUrl = AppConstants.defaultFallbackUrl,
    this.expiresAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.qrConfig = const QrConfig(),
    this.clickCount = 0,
    this.lastClickedAt,
  });

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isEffectivelyActive => isActive && !isExpired;

  String fullShortUrl([String domain = AppConstants.defaultDomain]) {
    return 'https://$domain/$shortCode';
  }

  ShortLink copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? shortCode,
    String? destinationUrl,
    String? fallbackUrl,
    DateTime? expiresAt,
    bool? clearExpiresAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    QrConfig? qrConfig,
    int? clickCount,
    DateTime? lastClickedAt,
    bool? clearLastClickedAt,
  }) {
    return ShortLink(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      shortCode: shortCode ?? this.shortCode,
      destinationUrl: destinationUrl ?? this.destinationUrl,
      fallbackUrl: fallbackUrl ?? this.fallbackUrl,
      expiresAt: clearExpiresAt == true ? null : (expiresAt ?? this.expiresAt),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      qrConfig: qrConfig ?? this.qrConfig,
      clickCount: clickCount ?? this.clickCount,
      lastClickedAt: clearLastClickedAt == true ? null : (lastClickedAt ?? this.lastClickedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'shortCode': shortCode.toLowerCase(),
      'destinationUrl': destinationUrl,
      'fallbackUrl': fallbackUrl,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'qrConfig': qrConfig.toMap(),
      'clickCount': clickCount,
      'lastClickedAt': lastClickedAt != null ? Timestamp.fromDate(lastClickedAt!) : null,
    };
  }

  factory ShortLink.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ShortLink.fromMap(data, id: doc.id);
  }

  factory ShortLink.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return ShortLink(
      id: id ?? (map['id'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      shortCode: (map['shortCode'] as String? ?? '').toLowerCase(),
      destinationUrl: map['destinationUrl'] as String? ?? '',
      fallbackUrl: map['fallbackUrl'] as String? ?? AppConstants.defaultFallbackUrl,
      expiresAt: parseNullableDate(map['expiresAt']),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: parseDate(map['createdAt'], DateTime.now()),
      updatedAt: parseDate(map['updatedAt'], DateTime.now()),
      qrConfig: QrConfig.fromMap(map['qrConfig'] as Map<String, dynamic>?),
      clickCount: (map['clickCount'] as num?)?.toInt() ?? 0,
      lastClickedAt: parseNullableDate(map['lastClickedAt']),
    );
  }
}
