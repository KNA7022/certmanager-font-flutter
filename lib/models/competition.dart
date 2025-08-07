import 'package:flutter/material.dart';

class Competition {
  final int id;
  final int userId;
  final String? username;
  final String? userName;
  final String name;
  final String description;
  final String registrationStart;
  final String registrationEnd;
  final String startDate;
  final String endDate;
  final String status;
  final String createdAt;
  final String updatedAt;
  final int certificateCount;

  Competition({
    required this.id,
    required this.userId,
    this.username,
    this.userName,
    required this.name,
    required this.description,
    required this.registrationStart,
    required this.registrationEnd,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.certificateCount = 0,
  });

  factory Competition.fromJson(Map<String, dynamic> json) {
    return Competition(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      username: json['username'],
      userName: json['userName'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      registrationStart: json['registrationStart'] ?? '',
      registrationEnd: json['registrationEnd'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      certificateCount: json['certificateCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userName': userName,
      'name': name,
      'description': description,
      'registrationStart': registrationStart,
      'registrationEnd': registrationEnd,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'certificateCount': certificateCount,
    };
  }

  // 获取状态显示文本
  String get statusText {
    switch (status) {
      case 'UPCOMING':
        return '即将开始';
      case 'ONGOING':
        return '进行中';
      case 'COMPLETED':
        return '已结束';
      case 'CANCELLED':
        return '已取消';
      default:
        return '未知状态';
    }
  }

  // 获取状态颜色
  String get statusColor {
    switch (status) {
      case 'UPCOMING':
        return 'warning';
      case 'ONGOING':
        return 'success';
      case 'COMPLETED':
        return 'info';
      case 'CANCELLED':
        return 'danger';
      default:
        return 'secondary';
    }
  }

  // 获取状态显示文本方法
  String getStatusText() {
    return statusText;
  }

  // 获取状态颜色方法
  Color getStatusColor() {
    switch (status) {
      case 'UPCOMING':
        return Colors.orange;
      case 'ONGOING':
        return Colors.green;
      case 'COMPLETED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class CompetitionListResponse {
  final List<Competition> competitions;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool hasNext;
  final bool hasPrevious;

  CompetitionListResponse({
    required this.competitions,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory CompetitionListResponse.fromJson(Map<String, dynamic> json) {
    return CompetitionListResponse(
      competitions: (json['competitions'] as List<dynamic>? ?? [])
          .map((item) => Competition.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPage: json['currentPage'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrevious: json['hasPrevious'] ?? false,
    );
  }
}