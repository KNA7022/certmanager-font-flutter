import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../services/api_service.dart';
import '../models/competition.dart';
import '../models/certificate.dart';
import 'competition_list_screen.dart';
import 'my_certificates_screen.dart';
import 'profile_screen.dart';
import 'certificate_upload_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _username = '';
  bool _isLoading = true;
  List<Competition> _upcomingCompetitions = [];
  List<Certificate> _recentCertificates = [];

  final List<Widget> _pages = [
    const _HomePage(),
    const CompetitionListScreen(),
    const MyCertificatesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    print('=== _loadHomeData方法开始执行 ===');
    setState(() {
      _isLoading = true;
    });
    print('=== _isLoading设置为true ===');

    try {
      // 并行加载数据
      final futures = await Future.wait([
        ApiService.getCurrentUser(),
        ApiService.getMyCompetitions(),
        ApiService.getMyCertificates(),
      ]);

      // 添加调试输出
      print('=== API调试信息 ===');
      print('用户信息: ${futures[0]}');
      print('我的竞赛: ${futures[1]}');
      print('最近证书: ${futures[2]}');
      print('================');

      print('=== mounted检查 ===');
      print('mounted: $mounted');
      
      if (mounted) {
        print('=== 进入setState ===');
        setState(() {
          _username = futures[0]['data']['username'] ?? '';
          print('=== 用户名设置完成: $_username ===');
          // 处理单个竞赛对象返回格式
          print('=== 竞赛数据处理调试 ===');
          print('futures[1]["data"]: ${futures[1]['data']}');
          print('futures[1]["data"]类型: ${futures[1]['data'].runtimeType}');
          try {
            if (futures[1]['data'] != null) {
              final competition = Competition.fromJson(futures[1]['data']);
              _upcomingCompetitions = [competition];
              print('解析后的竞赛对象: ${competition.name}');
              print('_upcomingCompetitions长度: ${_upcomingCompetitions.length}');
            } else {
              _upcomingCompetitions = [];
              print('竞赛数据为空');
            }
          } catch (e) {
            print('竞赛数据解析错误: $e');
            _upcomingCompetitions = [];
          }
          print('最终_upcomingCompetitions: $_upcomingCompetitions');
          print('最终_upcomingCompetitions长度: ${_upcomingCompetitions.length}');
          // 处理证书数据，检查空值
          if (futures[2]['data'] != null && futures[2]['data']['certificates'] is List) {
            _recentCertificates = (futures[2]['data']['certificates'] as List)
                .map((json) => Certificate.fromJson(json))
                .toList();
          } else {
            _recentCertificates = [];
          }
          _isLoading = false;
          print('setState完成，_isLoading: $_isLoading');
        });
      }
    } catch (e) {
      print('加载数据时出错: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(),
          ..._pages.skip(1),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // 当切换到首页时，刷新数据
          if (index == 0) {
            _loadHomeData();
          }
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: '竞赛',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership),
            label: '证书',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('证书管理系统'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadHomeData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHomeData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 欢迎卡片
                    GFCard(
                      content: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '欢迎回来，$_username！',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '管理您的竞赛证书',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 快捷操作
                    const Text(
                      '快捷操作',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            '浏览竞赛',
                            Icons.emoji_events,
                            Colors.orange,
                            () {
                              setState(() {
                                _currentIndex = 1;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickActionCard(
                            '上传证书',
                            Icons.upload_file,
                            Colors.green,
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CertificateUploadScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadHomeData();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickActionCard(
                            '我的证书',
                            Icons.card_membership,
                            Colors.blue,
                            () {
                              setState(() {
                                _currentIndex = 2;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 我的竞赛
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '我的竞赛',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_upcomingCompetitions.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentIndex = 1;
                              });
                            },
                            child: const Text('查看更多'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildUpcomingCompetitions(),
                    const SizedBox(height: 20),

                    // 最近的证书
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '最近的证书',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_recentCertificates.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentIndex = 2;
                              });
                            },
                            child: const Text('查看更多'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRecentCertificates(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GFCard(
      content: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingCompetitions() {
    print('=== _buildUpcomingCompetitions调试 ===');
    print('_upcomingCompetitions.isEmpty: ${_upcomingCompetitions.isEmpty}');
    print('_upcomingCompetitions.length: ${_upcomingCompetitions.length}');
    print('_upcomingCompetitions内容: $_upcomingCompetitions');
    
    if (_upcomingCompetitions.isEmpty) {
      return GFCard(
        content: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.event_busy,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                '暂无我的竞赛',
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

    return Column(
      children: _upcomingCompetitions.map((competition) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GFCard(
            content: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange[100],
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.orange[800],
                ),
              ),
              title: Text(
                competition.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '开始时间: ${_formatDate(competition.startDate)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: competition.getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  competition.getStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: competition.getStatusColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentCertificates() {
    if (_recentCertificates.isEmpty) {
      return GFCard(
        content: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.description_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                '暂无证书记录',
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

    return Column(
      children: _recentCertificates.map((certificate) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: GFCard(
            content: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Icon(
                  certificate.isImageFile() ? Icons.image : Icons.picture_as_pdf,
                  color: Colors.blue[800],
                ),
              ),
              title: Text(
                certificate.competitionName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '上传时间: ${certificate.getFormattedUploadTime()}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}