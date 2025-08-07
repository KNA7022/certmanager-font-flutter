import 'package:flutter/material.dart';
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
      
      // 处理单个竞赛对象返回格式
      if (response['data'] != null) {
        final competition = Competition.fromJson(response['data']);
        if (mounted) {
          setState(() {
            _myCompetitions = [competition];
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
    return GFCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      content: InkWell(
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
        child: CircularProgressIndicator(),
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
      appBar: AppBar(
        title: const Text('竞赛列表'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
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