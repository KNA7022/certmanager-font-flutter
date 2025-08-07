import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../models/certificate.dart';
import '../services/api_service.dart';
import 'competition_detail_screen.dart';
import '../utils/utils.dart';

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
              final fileSize = await tempFile.length();
              final result = await OpenFile.open(tempFile.path);
              if (result.type != ResultType.done) {
                 _showFileInfoDialog(tempFile, fileSize);
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

  void _showFileInfoDialog(File file, int fileSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
            SizedBox(width: 10),
            Text('文件信息', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRowDialog('文件名称', _certificate?.fileName ?? 'N/A'),
            SizedBox(height: 8),
            _buildInfoRowDialog('文件大小', formatFileSize(fileSize)),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            Text(
              '无法直接预览',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange.shade800),
            ),
            SizedBox(height: 8),
            Text(
              '此文件类型不支持在应用内预览，但已保存到临时目录。您可以尝试使用其他应用打开。',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            SizedBox(height: 8),
            SelectableText(
              '路径: ${file.path}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              OpenFile.open(file.path);
            },
            child: Text('用其他应用打开', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowDialog(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: Colors.grey.shade800))),
      ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            SizedBox(width: 10),
            Text('确认删除', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('您确定要永久删除证书 "${_certificate!.fileName}" 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: Colors.grey.shade700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: Text('确认删除', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildCertificatePreviewCard() {
    final isPdf = _certificate!.isPdf;
    final iconColor = isPdf ? Colors.red.shade600 : Colors.blue.shade600;
    final bgColor = isPdf ? Colors.red.shade50 : Colors.blue.shade50;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded, size: 48, color: iconColor),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _certificate!.fileName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          _certificate!.fileExtension.toUpperCase(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: iconColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _viewCertificate,
              icon: Icon(Icons.visibility_rounded, size: 20),
              label: Text('查看/下载证书'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateDetailsCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('详细信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.person_outline, '上传者', _certificate!.username),
            const Divider(height: 24),
            _buildDetailRow(Icons.calendar_today_outlined, '上传时间', _certificate!.formattedUploadTime),
            const Divider(height: 24),
            _buildDetailRow(Icons.sd_storage_outlined, '文件类型', _certificate!.fileExtension.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionInfoCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CompetitionDetailScreen(competitionId: _certificate!.competitionId)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('关联竞赛', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey.shade600),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.emoji_events_rounded, color: Colors.orange.shade600, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _certificate!.competitionName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text('点击查看竞赛详情', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildActionButton(
              icon: Icons.copy_all_rounded,
              label: '复制证书分享链接',
              onTap: () => _copyToClipboard(_certificate!.filePath),
            ),
            const Divider(height: 1),
            _buildActionButton(
              icon: Icons.delete_forever_rounded,
              label: '删除证书',
              color: Colors.red.shade600,
              onTap: _deleteCertificate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, Color? color, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 16),
        Text('$label:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: TextStyle(fontSize: 15, color: Colors.grey.shade800), textAlign: TextAlign.end)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_certificate?.fileName ?? '证书详情'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? Center(child: SpinKitFadingCube(color: Theme.of(context).primaryColor, size: 50.0))
          : _isDeleting
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitFadingCube(color: Theme.of(context).primaryColor, size: 50.0),
                      const SizedBox(height: 24),
                      Text('正在删除证书...', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      if (_certificate != null) ...[
                        _buildCertificatePreviewCard(),
                        _buildCertificateDetailsCard(),
                        _buildCompetitionInfoCard(),
                        _buildActionsCard(),
                      ]
                    ],
                  ),
                ),
    );
  }
}