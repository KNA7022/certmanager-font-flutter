import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/competition.dart';
import '../models/certificate.dart';
import '../utils/storage_helper.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';
  
  // 用户注册
  static Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String realName,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
          'realName': realName,
          'email': email,
        }),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': '网络请求失败: $e',
        'data': null,
        'code': 500,
      };
    }
  }
  
  // 用户登录
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      
      final result = jsonDecode(response.body);
      
      // 如果登录成功，保存token
      if (result['success'] == true && result['data']['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', result['data']['token']);
        await prefs.setString('user_info', jsonEncode(result['data']['user']));
      }
      
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': '网络请求失败: $e',
        'data': null,
        'code': 500,
      };
    }
  }
  
  // 获取保存的token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // 获取用户信息
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoStr = prefs.getString('user_info');
    if (userInfoStr != null) {
      return jsonDecode(userInfoStr);
    }
    return null;
  }
  
  // 清除登录信息
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_info');
  }

  // 获取当前用户信息
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();
    print('=== getCurrentUser调试信息 ===');
    print('Token: ${token?.substring(0, 20)}...');
    if (token == null) {
      throw Exception('未登录');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('getCurrentUser响应状态码: ${response.statusCode}');
    print('getCurrentUser响应体: ${response.body}');
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '获取用户信息失败');
    }
  }

  // 更新用户信息
  static Future<Map<String, dynamic>> updateUser({
    required int id, // 添加id参数
    required String username,
    required String email,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'), // 修改URL
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '更新用户信息失败');
    }
  }

  // 修改密码
  static Future<Map<String, dynamic>> changePassword({
    required int id, // 添加id参数
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/users/$id/password'), // 修改URL
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '修改密码失败');
    }
  }

  // ==================== 竞赛相关API ====================
  
  // 获取公开竞赛列表
  static Future<Map<String, dynamic>> getPublicCompetitions({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
    String sortDir = 'desc',
    String search = '',
  }) async {
    final queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'sortBy': sortBy,
      'sortDir': sortDir,
      if (search.isNotEmpty) 'search': search,
    };
    
    final uri = Uri.parse('$baseUrl/competitions/public').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri);
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '获取竞赛列表失败');
    }
  }

  // 获取我的竞赛
  static Future<Map<String, dynamic>> getMyCompetitions({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
    String sortDir = 'desc',
  }) async {
    final token = await getToken();
    print('=== getMyCompetitions调试信息 ===');
    print('Token: ${token?.substring(0, 20)}...');
    if (token == null) {
      throw Exception('未登录');
    }

    // 先获取当前用户信息以获得用户ID
    final userInfo = await getCurrentUser();
    final userId = userInfo['data']['id'];
    print('当前用户ID: $userId');

    final queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'sortBy': sortBy,
      'sortDir': sortDir,
    };
    
    final uri = Uri.parse('$baseUrl/competitions/$userId').replace(
      queryParameters: queryParams,
    );
    print('请求URL: $uri');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    print('getMyCompetitions响应状态码: ${response.statusCode}');
    print('getMyCompetitions响应体: ${response.body}');
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '获取我的竞赛失败');
    }
  }

  // 获取即将开始的竞赛
  static Future<Map<String, dynamic>> getUpcomingCompetitions() async {
    final token = await getToken();
    print('=== getUpcomingCompetitions调试信息 ===');
    print('Token: ${token?.substring(0, 20)}...');
    print('请求URL: $baseUrl/competitions/upcoming');
    
    final response = await http.get(
      Uri.parse('$baseUrl/competitions/upcoming'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    
    print('getUpcomingCompetitions响应状态码: ${response.statusCode}');
    print('getUpcomingCompetitions响应体: ${response.body}');
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '获取即将开始的竞赛失败');
    }
  }

  // 获取最近的竞赛
  static Future<Map<String, dynamic>> getRecentCompetitions() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/competitions/recent'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '获取最近的竞赛失败');
    }
  }

  // 根据竞赛ID获取竞赛详情
  static Future<Map<String, dynamic>> getCompetitionById(int id) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/competitions/detail/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '获取竞赛详情失败');
    }
  }

  // 创建竞赛
  static Future<Map<String, dynamic>> createCompetition({
    required String name,
    required String description,
    required String registrationStart,
    required String registrationEnd,
    required String startDate,
    required String endDate,
    required String status,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/competitions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'registrationStart': registrationStart,
        'registrationEnd': registrationEnd,
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
      }),
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '创建竞赛失败');
    }
  }

  // ==================== 证书相关API ====================
  
  // 上传证书
  static Future<Map<String, dynamic>> uploadCertificate({
    required int competitionId,
    required File file,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/certificates/upload'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['competitionId'] = competitionId.toString();
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '上传证书失败');
    }
  }

  // 获取我的证书
  static Future<Map<String, dynamic>> getMyCertificates({
    int page = 0,
    int size = 10,
    String sortBy = 'id',
    String sortDir = 'desc',
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }

    final queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'sortBy': sortBy,
      'sortDir': sortDir,
    };
    
    final uri = Uri.parse('$baseUrl/certificates/my').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '获取我的证书失败');
    }
  }

  // 根据竞赛ID获取证书
  static Future<Map<String, dynamic>> getCertificatesByCompetition(
    int competitionId, {
    int page = 0,
    int size = 10,
    String sortBy = 'id',
    String sortDir = 'desc',
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }

    final queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      'sortBy': sortBy,
      'sortDir': sortDir,
    };
    
    final uri = Uri.parse('$baseUrl/certificates/competition/$competitionId').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final data = jsonDecode(response.body);
    
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '获取竞赛证书失败');
    }
  }

  // 获取最近上传的证书
  static Future<Map<String, dynamic>> getRecentCertificates() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/certificates/recent'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '获取最近证书失败');
    }
  }

  // 根据ID获取证书详情
  static Future<Map<String, dynamic>> getCertificateById(int id) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/certificates/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '获取证书详情失败');
    }
  }

  // 删除证书
  static Future<Map<String, dynamic>> deleteCertificate(int id) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/certificates/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success']) {
      return data;
    } else {
      throw Exception(data['message'] ?? '删除证书失败');
    }
  }

  // 获取证书文件URL（用于查看/下载）
  static String getCertificateViewUrl(int id) {
    return '$baseUrl/certificates/$id/view';
  }

  // 查看证书文件
  static Future<Map<String, dynamic>> viewCertificate(int id) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/certificates/$id/view'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': response.bodyBytes,
        'contentType': response.headers['content-type'] ?? 'application/octet-stream',
      };
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? '查看证书失败');
    }
  }

  // 下载证书文件
  static Future<Map<String, dynamic>> downloadCertificate(int id) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/certificates/$id/download'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'data': response.bodyBytes,
        'contentType': response.headers['content-type'] ?? 'application/octet-stream',
        'fileName': _extractFileName(response.headers),
      };
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? '下载证书失败');
    }
  }

  // 从响应头中提取文件名
  static String _extractFileName(Map<String, String> headers) {
    final contentDisposition = headers['content-disposition'];
    if (contentDisposition != null) {
      final match = RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
      if (match != null) {
        return match.group(1) ?? 'certificate';
      }
    }
    return 'certificate';
  }
}