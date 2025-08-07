import 'dart:io';
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../models/competition.dart';

class CertificateUploadScreen extends StatefulWidget {
  final int? competitionId;
  final String? competitionName;
  
  const CertificateUploadScreen({
    Key? key,
    this.competitionId,
    this.competitionName,
  }) : super(key: key);

  @override
  State<CertificateUploadScreen> createState() => _CertificateUploadScreenState();
}

class _CertificateUploadScreenState extends State<CertificateUploadScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  bool _isLoadingCompetitions = true;
  String? _fileName;
  String? _fileSize;
  String? _fileType;
  
  List<Competition> _competitions = [];
  Competition? _selectedCompetition;

  @override
  void initState() {
    super.initState();
    if (widget.competitionId != null && widget.competitionName != null) {
      // 如果传入了竞赛参数，直接创建竞赛对象
      _selectedCompetition = Competition(
        id: widget.competitionId!,
        userId: 0, // Default value since we don't have user info here
        username: '',
        userName: '',
        name: widget.competitionName!,
        description: '',
        registrationStart: '',
        registrationEnd: '',
        startDate: '',
        endDate: '',
        status: 'active',
        createdAt: '',
        updatedAt: '',
        certificateCount: 0,
      );
      _competitions = [_selectedCompetition!];
      _isLoadingCompetitions = false;
    } else {
      // 否则加载竞赛列表
      _loadCompetitions();
    }
  }

  Future<void> _loadCompetitions() async {
    setState(() {
      _isLoadingCompetitions = true;
    });

    try {
      final response = await ApiService.getMyCompetitions();
      final List<dynamic> competitionsData = response['data']['competitions'];
      
      setState(() {
        _competitions = competitionsData.map((json) => Competition.fromJson(json)).toList();
        _isLoadingCompetitions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCompetitions = false;
      });
      
      if (mounted) {
        GFToast.showToast(
          '加载竞赛列表失败: ${e.toString()}',
          context,
          toastPosition: GFToastPosition.CENTER,
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size;
        final fileExtension = fileName.split('.').last.toLowerCase();

        // 检查文件大小（限制为10MB）
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            GFToast.showToast(
              '文件大小不能超过10MB',
              context,
              toastPosition: GFToastPosition.CENTER,
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          _fileName = fileName;
          _fileSize = _formatFileSize(fileSize);
          _fileType = _getFileTypeDescription(fileExtension);
        });
      }
    } catch (e) {
      if (mounted) {
        GFToast.showToast(
          '选择文件失败: ${e.toString()}',
          context,
          toastPosition: GFToastPosition.CENTER,
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String _getFileTypeDescription(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'PDF文档';
      case 'jpg':
      case 'jpeg':
        return 'JPEG图片';
      case 'png':
        return 'PNG图片';
      default:
        return '未知类型';
    }
  }

  Future<void> _uploadCertificate() async {
    if (_selectedFile == null) {
      GFToast.showToast(
        '请先选择文件',
        context,
        toastPosition: GFToastPosition.CENTER,
      );
      return;
    }

    if (_selectedCompetition == null) {
      GFToast.showToast(
        '请选择竞赛',
        context,
        toastPosition: GFToastPosition.CENTER,
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await ApiService.uploadCertificate(
        competitionId: _selectedCompetition!.id,
        file: _selectedFile!,
      );

      if (mounted) {
        GFToast.showToast(
          '证书上传成功',
          context,
          toastPosition: GFToastPosition.CENTER,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        GFToast.showToast(
          '上传失败: ${e.toString()}',
          context,
          toastPosition: GFToastPosition.CENTER,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileSize = null;
      _fileType = null;
    });
  }

  Widget _buildFilePreview() {
    if (_selectedFile == null) {
      return GFCard(
        content: Container(
          height: 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '点击选择文件',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '支持 PDF、JPG、PNG 格式\n文件大小不超过 10MB',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GFCard(
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _fileName!.toLowerCase().endsWith('.pdf')
                      ? Icons.picture_as_pdf
                      : Icons.image,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_fileType • $_fileSize',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _removeFile,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionSelector() {
    // 如果传入了竞赛参数，显示竞赛信息
    if (widget.competitionId != null && widget.competitionName != null) {
      return GFCard(
        content: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '竞赛信息',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.competitionName!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    // 否则显示竞赛选择器
    if (_isLoadingCompetitions) {
      return GFCard(
        content: Container(
          height: 60,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_competitions.isEmpty) {
      return GFCard(
        content: Container(
          height: 60,
          child: Center(
            child: Text(
              '暂无可用竞赛',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return GFCard(
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择竞赛',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Competition>(
              value: _selectedCompetition,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '请选择竞赛',
              ),
              items: _competitions.map((competition) {
                return DropdownMenuItem<Competition>(
                  value: competition,
                  child: Text(
                    competition.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (Competition? value) {
                setState(() {
                  _selectedCompetition = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('上传证书'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompetitionSelector(),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickFile,
              child: _buildFilePreview(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: GFButton(
                onPressed: _isUploading ? null : _uploadCertificate,
                text: _isUploading ? '上传中...' : '上传证书',
                color: Colors.blue,
                size: GFSize.LARGE,
                type: GFButtonType.solid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}