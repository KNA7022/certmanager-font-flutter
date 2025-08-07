import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:getwidget/getwidget.dart';
import '../models/competition.dart';
import '../services/api_service.dart';
import 'competition_detail_screen.dart';
import 'create_competition_screen.dart';

class CompetitionListScreen extends StatefulWidget {
  const CompetitionListScreen({Key? key}) : super(key: key);

  @override
  State<CompetitionListScreen> createState() => _CompetitionListScreenState();
}

class _CompetitionListScreenState extends State<CompetitionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Competition> _myCompetitions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadMyCompetitions();
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

  Future<void> _loadMyCompetitions() async {
    try {
      final response = await ApiService.getMyCompetitions();
      print('=== 我的竞赛API调试信息 ===');
      print('API返回数据: $response');
      print('========================');
      
      // 处理竞赛列表数据
      if (response['data'] != null && response['data'] is List) {
        final competitions = (response['data'] as List)
            .map((json) => Competition.fromJson(json))
            .toList();
        if (mounted) {
          setState(() {
            _myCompetitions = competitions;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _myCompetitions = [];
          });
        }
      }
    } catch (e) {
      print('加载我的竞赛时出错: $e');
      // 如果用户未登录，忽略错误
      if (!e.toString().contains('未登录')) {
        rethrow;
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  Widget _buildCompetitionCard(Competition competition) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompetitionDetailScreen(
                competitionId: competition.id,
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
                  Expanded(
                    child: Text(
                      competition.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GFBadge(
                    text: competition.statusText,
                    color: _getStatusColor(competition.status),
                    size: GFSize.SMALL,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                competition.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    competition.userName ?? '未知用户',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.verified_user,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${competition.certificateCount} 证书',
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
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(competition.startDate)} - ${_formatDate(competition.endDate)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildCompetitionList(List<Competition> competitions, bool isPublic) {
    if (_isLoading && competitions.isEmpty) {
      return const Center(
        child: SpinKitFadingCube(color: GFColors.PRIMARY, size: 50.0),
      );
    }

    if (competitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无我的竞赛',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        itemCount: competitions.length,
        itemBuilder: (context, index) {
          return _buildCompetitionCard(competitions[index]);
        },
      ),
    );
  }

  Future<void> _navigateToCreateCompetition() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCompetitionScreen(),
      ),
    );
    
    // 如果创建成功，刷新列表
    if (result == true) {
      _onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('竞赛列表', style: TextStyle(color: GFColors.DARK, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: GFColors.DARK,
        bottom: TabBar(
          controller: _tabController,
          labelColor: GFColors.DARK,
          unselectedLabelColor: Colors.grey,
          indicatorColor: GFColors.PRIMARY,
          tabs: const [
            Tab(text: '我的竞赛'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCompetitionList(_myCompetitions, false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateCompetition,
        backgroundColor: Colors.blue,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        tooltip: '创建竞赛',
      ),
    );
  }
}