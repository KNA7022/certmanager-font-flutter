import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever_outlined, color: Colors.red.shade700),
            const SizedBox(width: 10),
            const Text('确认删除', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('您确定要永久删除证书 "${certificate.fileName}" 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('确认删除'),
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
    final iconColor = certificate.isPdf ? Colors.red.shade700 : Colors.blue.shade700;
    final backgroundColor = certificate.isPdf ? Colors.red.shade50 : Colors.blue.shade50;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CertificateDetailScreen(certificateId: certificate.id)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
                    child: Icon(certificate.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined, size: 36, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certificate.fileName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          certificate.competitionName,
                          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  _buildPopupMenu(certificate),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_filled_rounded, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '上传于: ${certificate.formattedUploadTime}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade500),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuButton<String> _buildPopupMenu(Certificate certificate) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'view_competition':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CompetitionDetailScreen(competitionId: certificate.competitionId)),
            );
            break;
          case 'delete':
            _deleteCertificate(certificate);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'view_competition',
          child: Row(children: [Icon(Icons.emoji_events_outlined, color: Theme.of(context).primaryColor), const SizedBox(width: 12), const Text('查看竞赛')]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red.shade700), const SizedBox(width: 12), Text('删除证书', style: TextStyle(color: Colors.red.shade700))]),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_outlined, size: 120, color: Theme.of(context).primaryColor.withOpacity(0.6)),
            const SizedBox(height: 24),
            Text('证书收藏夹为空', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 12),
            Text(
              '你上传的所有证书都会在这里展示。\n立即参加一场竞赛，赢取你的第一份荣誉吧！',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/competitions'),
              icon: const Icon(Icons.emoji_events_outlined),
              label: const Text('探索热门竞赛'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('我的证书'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: _onRefresh,
            icon: Icon(Icons.refresh_rounded, color: Theme.of(context).primaryColor),
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading && _certificates.isEmpty
          ? Center(child: SpinKitFadingCube(color: Theme.of(context).primaryColor, size: 50.0))
          : _certificates.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: Theme.of(context).primaryColor,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _certificates.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _certificates.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SpinKitFadingCube(color: Theme.of(context).primaryColor, size: 30.0),
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