import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:getwidget/getwidget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/certificate.dart';
import '../services/api_service.dart';
import 'competition_detail_screen.dart';

class CertificateDetailScreen extends StatefulWidget {
  final int certificateId;

  const CertificateDetailScreen({
    Key? key,
    required this.certificateId,
  }) : super(key: key);

  @override
  State<CertificateDetailScreen> createState() => _CertificateDetailScreenState();
}

class _CertificateDetailScreenState extends State<CertificateDetailScreen> {
  Certificate? _certificate;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadCertificateDetail();
  }

  Future<void> _loadCertificateDetail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getCertificateById(widget.certificateId);
      final certificate = Certificate.fromJson(response['data']);
      
      if (mounted) {
        setState(() {
          _certificate = certificate;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载证书详情失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _viewCertificate() async {
    if (_certificate == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 通过API获取证书文件数据
      print('开始获取证书文件，ID: ${_certificate!.id}');
      final response = await ApiService.viewCertificate(_certificate!.id);
      print('API响应: ${response?.keys}');
      print('响应成功状态: ${response?['success']}');
      print('数据类型: ${response?['data']?.runtimeType}');
      print('数据长度: ${response?['data']?.length}');
      
      if (response != null && response['success'] == true && response['data'] != null) {
         // 获取应用文档目录
         final tempDir = await getApplicationDocumentsDirectory();
         final fileName = _certificate!.fileName;
         final tempFile = File('${tempDir.path}/$fileName');
         
         // 将文件数据写入临时文件
         final bytes = response['data'] as Uint8List;
         if (bytes.isNotEmpty) {
            await tempFile.writeAsBytes(bytes);
            
            // 检查文件是否为图像格式
            final extension = fileName.toLowerCase().split('.').last;
            if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
              // 在应用内显示图像
              _showImageDialog(tempFile);
            } else {
              // 非图像文件，尝试用外部应用打开
              final uri = Uri.file(tempFile.path);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                // 如果无法打开，显示文件信息
                _showFileInfoDialog(tempFile);
              }
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('证书文件数据为空'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('无法获取证书文件'),
               backgroundColor: Colors.red,
             ),
           );
         }
    } catch (e, stackTrace) {
      print('查看证书时出错: $e');
      print('错误堆栈: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('查看证书时出错: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCertificateDialog() {
    final certificateUrl = 'http://10.0.2.2:8080/api/certificates/${_certificate!.id}/view';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.card_membership, color: Colors.blue),
            SizedBox(width: 8),
            Text('证书详情'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('文件名', _certificate!.fileName),
              _buildInfoRow('竞赛名称', _certificate!.competitionName),
              _buildInfoRow('上传者', _certificate!.username),
              _buildInfoRow('上传时间', _formatDateTime(_certificate!.uploadedAt)),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          '查看说明',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '由于移动端限制，请复制以下链接到浏览器中查看证书文件：',
                      style: TextStyle(fontSize: 13),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        certificateUrl,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 复制链接到剪贴板
              _copyToClipboard(certificateUrl);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy, size: 16),
                SizedBox(width: 4),
                Text('复制链接'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  void _showImageDialog(File imageFile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text('证书预览'),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Image.file(
                          imageFile,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, size: 48, color: Colors.red),
                                  SizedBox(height: 8),
                                  Text('无法加载图像'),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '证书信息',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildInfoRow('文件名', _certificate!.fileName),
                              _buildInfoRow('竞赛名称', _certificate!.competitionName),
                              _buildInfoRow('上传者', _certificate!.username),
                              _buildInfoRow('上传时间', _formatDateTime(_certificate!.uploadedAt)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFileInfoDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.insert_drive_file, color: Colors.blue),
            SizedBox(width: 8),
            Text('证书文件'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('文件名', _certificate!.fileName),
            _buildInfoRow('竞赛名称', _certificate!.competitionName),
            _buildInfoRow('上传者', _certificate!.username),
            _buildInfoRow('上传时间', _formatDateTime(_certificate!.uploadedAt)),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        '文件已下载',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '证书文件已保存到临时目录，但无法在应用内预览此文件格式。',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '文件路径: ${file.path}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('链接已复制到剪贴板'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('复制失败，请手动复制链接'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteCertificate() async {
    if (_certificate == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除证书"${_certificate!.fileName}"吗？\n删除后将无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        await ApiService.deleteCertificate(_certificate!.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('证书删除成功'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // 返回true表示已删除
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  Widget _buildCertificateInfo() {
    if (_certificate == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // 证书文件信息卡片
        GFCard(
          margin: const EdgeInsets.all(16),
          content: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 文件图标和基本信息
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _certificate!.isPdf ? Colors.red[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _certificate!.isPdf ? Icons.picture_as_pdf : Icons.image,
                        size: 48,
                        color: _certificate!.isPdf ? Colors.red : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _certificate!.fileName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _certificate!.isPdf ? Colors.red[100] : Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _certificate!.fileExtension.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _certificate!.isPdf ? Colors.red[800] : Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // 查看和下载按钮
                Row(
                  children: [
                    Expanded(
                      child: GFButton(
                        onPressed: _viewCertificate,
                        text: '查看证书',
                        type: GFButtonType.solid,
                        color: Colors.blue,
                        icon: const Icon(
                          Icons.visibility,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GFButton(
                        onPressed: _viewCertificate,
                        text: '下载证书',
                        type: GFButtonType.outline,
                        color: Colors.blue,
                        icon: Icon(
                          Icons.download,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // 详细信息卡片
        GFCard(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          content: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '证书信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('证书ID', _certificate!.id.toString()),
                const SizedBox(height: 12),
                _buildInfoRow('文件名称', _certificate!.fileName),
                const SizedBox(height: 12),
                _buildInfoRow('上传者', _certificate!.username),
                const SizedBox(height: 12),
                _buildInfoRow('上传时间', _certificate!.formattedUploadTime),
              ],
            ),
          ),
        ),
        
        // 关联竞赛信息卡片
        GFCard(
          margin: const EdgeInsets.all(16),
          content: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompetitionDetailScreen(
                    competitionId: _certificate!.competitionId,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '关联竞赛',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.orange[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _certificate!.competitionName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '点击查看竞赛详情',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_certificate?.fileName ?? '证书详情'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_certificate != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _deleteCertificate();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('删除证书', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isDeleting
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在删除证书...'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: _buildCertificateInfo(),
                ),
    );
  }
}