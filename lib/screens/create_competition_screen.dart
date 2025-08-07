import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/api_service.dart';
import 'package:another_flushbar/flushbar.dart';

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

  void _showErrorFlushbar(String message) {
    Flushbar(
      message: message,
      duration: Duration(seconds: 3),
      backgroundColor: Colors.red.shade600,
      icon: Icon(Icons.error_outline, color: Colors.white),
      leftBarIndicatorColor: Colors.red.shade900,
    ).show(context);
  }

  Future<void> _createCompetition() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorFlushbar('请填写所有必填项');
      return;
    }

    if (_registrationStartDate == null ||
        _registrationEndDate == null ||
        _startDate == null ||
        _endDate == null) {
      _showErrorFlushbar('请选择所有相关的日期和时间');
      return;
    }

    if (_registrationStartDate!.isAfter(_registrationEndDate!)) {
      _showErrorFlushbar('报名开始时间不能晚于报名结束时间');
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      _showErrorFlushbar('竞赛开始时间不能晚于竞赛结束时间');
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

      if (mounted) {
        Flushbar(
          message: '竞赛创建成功！',
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green.shade600,
          icon: Icon(Icons.check_circle_outline, color: Colors.white),
          leftBarIndicatorColor: Colors.green.shade900,
        ).show(context).then((_) => Navigator.pop(context, true));
      }
    } catch (e) {
      _showErrorFlushbar('创建失败: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildDateTimeSelector(String label, DateTime? dateTime, String type, IconData icon) {
    return InkWell(
      onTap: () => _selectDateTime(context, type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(dateTime),
                    style: TextStyle(
                      color: dateTime == null ? Colors.grey.shade600 : Colors.black87,
                      fontSize: 15,
                      fontWeight: dateTime == null ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('创建新竞赛'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              _buildTimeCard(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('基本信息', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '竞赛名称',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.emoji_events_outlined),
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? '请输入竞赛名称' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '竞赛描述',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
              validator: (value) => (value == null || value.trim().isEmpty) ? '请输入竞赛描述' : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(
                labelText: '竞赛状态',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'UPCOMING', child: Text('即将开始')),
                DropdownMenuItem(value: 'ONGOING', child: Text('进行中')),
                DropdownMenuItem(value: 'COMPLETED', child: Text('已结束')),
              ],
              onChanged: (value) => setState(() => _status = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('时间设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDateTimeSelector('报名开始时间', _registrationStartDate, 'registrationStart', Icons.how_to_reg_outlined),
            _buildDateTimeSelector('报名结束时间', _registrationEndDate, 'registrationEnd', Icons.event_busy_outlined),
            const Divider(height: 24),
            _buildDateTimeSelector('竞赛开始时间', _startDate, 'start', Icons.play_circle_outline_rounded),
            _buildDateTimeSelector('竞赛结束时间', _endDate, 'end', Icons.check_circle_outline_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _createCompetition,
      icon: _isLoading
          ? SizedBox.shrink()
          : Icon(Icons.add_circle_outline_rounded),
      label: _isLoading
          ? SpinKitFadingCube(color: Colors.white, size: 24)
          : Text('确认创建', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }
}