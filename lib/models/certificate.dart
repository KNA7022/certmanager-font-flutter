class Certificate {
  final int id;
  final int competitionId;
  final String competitionName;
  final String username;
  final String fileName;
  final String filePath;
  final String uploadedAt;

  Certificate({
    required this.id,
    required this.competitionId,
    required this.competitionName,
    required this.username,
    required this.fileName,
    required this.filePath,
    required this.uploadedAt,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] ?? 0,
      competitionId: json['competitionId'] ?? 0,
      competitionName: json['competitionName'] ?? '',
      username: json['username'] ?? '',
      fileName: json['fileName'] ?? '',
      filePath: json['filePath'] ?? '',
      uploadedAt: json['uploadedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'competitionId': competitionId,
      'competitionName': competitionName,
      'username': username,
      'fileName': fileName,
      'filePath': filePath,
      'uploadedAt': uploadedAt,
    };
  }

  // 获取文件扩展名
  String get fileExtension {
    return fileName.split('.').last.toLowerCase();
  }

  // 判断是否为PDF文件
  bool get isPdf => fileExtension == 'pdf';

  // 判断是否为图片文件
  bool get isImage => ['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension);

  // 获取格式化的上传时间
  String get formattedUploadTime {
    try {
      String parsableDate = uploadedAt;
      // 如果时间格式是 YYYY-MM-DDTHH:mm，补全秒数
      if (RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$').hasMatch(parsableDate)) {
        parsableDate += ':00';
      }
      final dateTime = DateTime.parse(parsableDate);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('日期解析错误: $e, 原始值: $uploadedAt');
      return uploadedAt;
    }
  }

  // 判断是否为图片文件方法
  bool isImageFile() {
    return isImage;
  }

  // 获取格式化的上传时间方法
  String getFormattedUploadTime() {
    return formattedUploadTime;
  }
}

class CertificateListResponse {
  final List<Certificate> certificates;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool hasNext;
  final bool hasPrevious;

  CertificateListResponse({
    required this.certificates,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory CertificateListResponse.fromJson(Map<String, dynamic> json) {
    return CertificateListResponse(
      certificates: (json['certificates'] as List<dynamic>? ?? [])
          .map((item) => Certificate.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPage: json['currentPage'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrevious: json['hasPrevious'] ?? false,
    );
  }
}