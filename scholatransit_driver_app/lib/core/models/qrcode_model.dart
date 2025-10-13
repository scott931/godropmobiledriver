class QrCodeInfo {
  final int id;
  final Map<String, dynamic> student;
  final String qrCodeData;
  final String qrCodeImage;
  final String qrCodeUrl;
  final bool isActive;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QrCodeInfo({
    required this.id,
    required this.student,
    required this.qrCodeData,
    required this.qrCodeImage,
    required this.qrCodeUrl,
    required this.isActive,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QrCodeInfo.fromJson(Map<String, dynamic> json) {
    return QrCodeInfo(
      id: json['id'] ?? 0,
      student: json['student'] as Map<String, dynamic>? ?? const {},
      qrCodeData: json['qr_code_data'] ?? '',
      qrCodeImage: json['qr_code_image'] ?? json['qr_code_url'] ?? '',
      qrCodeUrl: json['qr_code_url'] ?? json['qr_code_image'] ?? '',
      isActive: json['is_active'] ?? false,
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}


