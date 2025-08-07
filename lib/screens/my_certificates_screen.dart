import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../models/certificate.dart';
import '../services/api_service.dart';
import 'certificate_detail_screen.dart';
import 'competition_detail_screen.dart';

class MyCertificatesScreen extends StatefulWidget {
  const MyCertificatesScreen({Key? key}) : super(key: key);

  @override
  State<MyCertificatesScreen> createState() => _MyCertificatesScreenState();
}

class _MyCertificatesScreenState extends State<MyCertificatesScreen> {
  List<Certificate> _certificates = [];
  bool _isLoading = false;
  int _currentPage = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCertificates();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent &&
        _hasMore &&
        !_isLoading) {
      _loadMore();
    }
  }

  Future<void> _loadCertificates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getMyCertificates(
        page: _currentPage,
      );
      
      final certificateList = CertificateListResponse.fromJson(response['data']);
      
      if (mounted) {
        setState(() {
          if (_currentPage == 0) {
            _certificates = certificateList.certificates;
          } else {
            _certificates.addAll(certificateList.certificates);
          }
          _hasMore = certificateList.hasNext;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载证书失败: ${e.toString()}'),
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

  Future<void> _loadMore() async {
    if (_hasMore && !_isLoading) {
      _currentPage++;
      await _loadCertificates();
    }
  }

  Future<void> _onRefresh() async {
    _currentPage = 0;
    await _loadCertificates();
  }

  Future<void> _deleteCertificate(Certificate certificate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除证书"${certificate.fileName}"吗？'),
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
      try {
        await ApiService.deleteCertificate(certificate.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('证书删除成功'),
              backgroundColor: Colors.green,
            ),
          );
          _onRefresh();
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
      }
    }
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          certificate.competitionName,
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'view_competition':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CompetitionDetailScreen(
                                competitionId: certificate.competitionId,
                              ),
                            ),
                          );
                          break;
                        case 'delete':
                          _deleteCertificate(certificate);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view_competition',
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events, size: 20),
                            SizedBox(width: 8),
                            Text('查看竞赛'),
                          ],
                        ),
                      ),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '上传时间: ${certificate.formattedUploadTime}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GFButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CertificateDetailScreen(
                              certificateId: certificate.id,
                            ),
                          ),
                        );
                      },
                      text: '查看详情',
                      type: GFButtonType.outline,
                      color: Colors.blue,
                      size: GFSize.SMALL,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GFButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompetitionDetailScreen(
                              competitionId: certificate.competitionId,
                            ),
                          ),
                        );
                      },
                      text: '查看竞赛',
                      type: GFButtonType.solid,
                      color: Colors.blue,
                      size: GFSize.SMALL,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            '暂无证书',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '您还没有上传任何证书\n快去参加竞赛并上传您的证书吧！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          GFButton(
            onPressed: () {
              // 跳转到竞赛列表
              Navigator.pushReplacementNamed(context, '/competitions');
            },
            text: '浏览竞赛',
            type: GFButtonType.solid,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的证书'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading && _certificates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _certificates.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _certificates.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _certificates.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _buildCertificateCard(_certificates[index]);
                    },
                  ),
                ),
    );
  }
}