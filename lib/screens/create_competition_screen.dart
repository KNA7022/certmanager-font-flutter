import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../services/api_service.dart';

class CreateCompetitionScreen extends StatefulWidget {
  const CreateCompetitionScreen({Key? key}) : super(key: key);

  @override
  State<CreateCompetitionScreen> createState() => _CreateCompetitionScreenState();
}

class _CreateCompetitionScreenState extends State<CreateCompetitionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime? _registrationStartDate;
  DateTime? _registrationEndDate;
  DateTime? _startDate;
  DateTime? _endDate;
  
  String _status = 'UPCOMING';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, String type) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        setState(() {
          switch (type) {
            case 'registrationStart':
              _registrationStartDate = selectedDateTime;
              break;
            case 'registrationEnd':
              _registrationEndDate = selectedDateTime;
              break;
            case 'start':
              _startDate = selectedDateTime;
              break;
            case 'end':
              _endDate = selectedDateTime;
              break;
          }
        });
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '请选择时间';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTimeForApi(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}T${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _createCompetition() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_registrationStartDate == null ||
        _registrationEndDate == null ||
        _startDate == null ||
        _endDate == null) {
      GFToast.showToast(
        '请选择所有时间',
        context,
        toastPosition: GFToastPosition.CENTER,
      );
      return;
    }

    // 验证时间逻辑
    if (_registrationStartDate!.isAfter(_registrationEndDate!)) {
      GFToast.showToast(
        '报名开始时间不能晚于报名结束时间',
        context,
        toastPosition: GFToastPosition.CENTER,
      );
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      GFToast.showToast(
        '竞赛开始时间不能晚于竞赛结束时间',
        context,
        toastPosition: GFToastPosition.CENTER,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.createCompetition(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        registrationStart: _formatDateTimeForApi(_registrationStartDate!),
        registrationEnd: _formatDateTimeForApi(_registrationEndDate!),
        startDate: _formatDateTimeForApi(_startDate!),
        endDate: _formatDateTimeForApi(_endDate!),
        status: _status,
      );

      GFToast.showToast(
        '竞赛创建成功',
        context,
        toastPosition: GFToastPosition.CENTER,
      );

      Navigator.pop(context, true); // 返回true表示创建成功
    } catch (e) {
      GFToast.showToast(
        '创建失败: ${e.toString()}',
        context,
        toastPosition: GFToastPosition.CENTER,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildDateTimeSelector(String label, DateTime? dateTime, String type) {
    return GFCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      content: ListTile(
        title: Text(label),
        subtitle: Text(
          _formatDateTime(dateTime),
          style: TextStyle(
            color: dateTime == null ? Colors.grey : Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: () => _selectDateTime(context, type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建竞赛'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GFCard(
                content: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '基本信息',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '竞赛名称',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.emoji_events),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入竞赛名称';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: '竞赛描述',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入竞赛描述';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: '竞赛状态',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'UPCOMING',
                            child: Text('即将开始'),
                          ),
                          DropdownMenuItem(
                            value: 'ONGOING',
                            child: Text('进行中'),
                          ),
                          DropdownMenuItem(
                            value: 'COMPLETED',
                            child: Text('已结束'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GFCard(
                content: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '时间设置',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDateTimeSelector('报名开始时间', _registrationStartDate, 'registrationStart'),
                      _buildDateTimeSelector('报名结束时间', _registrationEndDate, 'registrationEnd'),
                      _buildDateTimeSelector('竞赛开始时间', _startDate, 'start'),
                      _buildDateTimeSelector('竞赛结束时间', _endDate, 'end'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: GFButton(
                  onPressed: _isLoading ? null : _createCompetition,
                  text: _isLoading ? '创建中...' : '创建竞赛',
                  color: Colors.blue,
                  size: GFSize.LARGE,
                  type: GFButtonType.solid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}