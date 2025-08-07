import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../models/competition.dart';
import '../models/certificate.dart';
import '../services/api_service.dart';
import 'certificate_upload_screen.dart';
import 'certificate_detail_screen.dart';

class CompetitionDetailScreen extends StatefulWidget {
  final int competitionId;

  const CompetitionDetailScreen({
    Key? key,
    required this.competitionId,
  }) : super(key: key);

  @override
  State<CompetitionDetailScreen> createState() => _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState extends State<CompetitionDetailScreen> {
  Competition? _competition;
  List<Certificate> _certificates = [];
  bool _isLoading = true;
  bool _isLoadingCertificates = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadCompetitionDetail(),
        _loadCertificates(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载数据失败: ${e.toString()}'),
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

  Future<void> _loadCompetitionDetail() async {
    try {
      final response = await ApiService.getCompetitionById(widget.competitionId);
      final competition = Competition.fromJson(response['data']);
      
      if (mounted) {
        setState(() {
          _competition = competition;
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadCertificates() async {
    setState(() {
      _isLoadingCertificates = true;
    });

    try {
      print('开始加载竞赛证书，竞赛ID: ${widget.competitionId}');
      final response = await ApiService.getCertificatesByCompetition(
        widget.competitionId,
      );
      print('证书API响应: $response');
      
      if (response['data'] != null) {
        final certificateList = CertificateListResponse.fromJson(response['data']);
        print('解析后的证书列表长度: ${certificateList.certificates.length}');
        
        if (mounted) {
          setState(() {
            _certificates = certificateList.certificates;
          });
        }
      } else {
        print('证书数据为空');
        if (mounted) {
          setState(() {
            _certificates = [];
          });
        }
      }
    } catch (e) {
      print('加载证书失败: $e');
      if (mounted) {
        setState(() {
          _certificates = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载证书失败: 服务器数据格式错误'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCertificates = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  void _navigateToUploadCertificate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificateUploadScreen(
          competitionId: widget.competitionId,
          competitionName: _competition?.name ?? '',
        ),
      ),
    );

    if (result == true) {
      _loadCertificates();
    }
  }

  Widget _buildCompetitionInfo() {
    if (_competition == null) {
      return const SizedBox.shrink();
    }

    return GFCard(
      margin: const EdgeInsets.all(16),
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _competition!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GFBadge(
                  text: _competition!.statusText,
                  color: _getStatusColor(_competition!.status),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '竞赛描述',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _competition!.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('创建者', _competition!.userName ?? '未知用户'),
            const SizedBox(height: 8),
            _buildInfoRow('报名时间', 
              '${_formatDateTime(_competition!.registrationStart)} - ${_formatDateTime(_competition!.registrationEnd)}'),
            const SizedBox(height: 8),
            _buildInfoRow('竞赛时间', 
              '${_formatDateTime(_competition!.startDate)} - ${_formatDateTime(_competition!.endDate)}'),
            const SizedBox(height: 8),
            _buildInfoRow('证书数量', '${_competition!.certificateCount}')
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                '相关证书',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GFButton(
                onPressed: _navigateToUploadCertificate,
                text: '上传证书',
                size: GFSize.SMALL,
                type: GFButtonType.solid,
                color: Colors.blue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCertificateList(),
      ],
    );
  }

  Widget _buildCertificateList() {
    if (_isLoadingCertificates) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_certificates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '暂无证书',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _certificates.length,
      itemBuilder: (context, index) {
        return _buildCertificateCard(_certificates[index]);
      },
    );
  }

  Widget _buildCertificateCard(Certificate certificate) {
    return GFCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CertificateDetailScreen(
                certificateId: certificate.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                certificate.isPdf ? Icons.picture_as_pdf : Icons.image,
                size: 40,
                color: certificate.isPdf ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      certificate.fileName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '上传者: ${certificate.username}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '上传时间: ${certificate.formattedUploadTime}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'UPCOMING':
        return GFColors.WARNING;
      case 'ONGOING':
        return GFColors.SUCCESS;
      case 'COMPLETED':
        return GFColors.INFO;
      case 'CANCELLED':
        return GFColors.DANGER;
      default:
        return GFColors.SECONDARY;
    }
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_competition?.name ?? '竞赛详情'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompetitionInfo(),
                    const SizedBox(height: 16),
                    _buildCertificateSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}