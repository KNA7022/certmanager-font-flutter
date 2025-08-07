import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:another_flushbar/flushbar.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/storage_helper.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUpdating = false;
  
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  
  // 修改密码相关
  final _passwordFormKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getCurrentUser();
      final user = User.fromJson(response['data']);
      
      if (mounted) {
        setState(() {
          _user = user;
          _usernameController.text = user.username;
          _emailController.text = user.email;
        });
      }
    } catch (e) {
      if (mounted) {
        Flushbar(
          title: '加载失败',
          message: e.toString(),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          titleColor: Colors.white,
          messageColor: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      if (_user == null) {
        throw Exception('无法获取用户信息');
      }
      await ApiService.updateUser(
        id: _user!.id,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        _loadUserInfo(); // 重新加载用户信息
        Flushbar(
          title: '成功',
          message: '个人信息更新成功',
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
          titleColor: Colors.white,
          messageColor: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        ).show(context);
      }
    } catch (e) {
      if (mounted) {
        Flushbar(
          title: '更新失败',
          message: e.toString(),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          titleColor: Colors.white,
          messageColor: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      if (_user == null) {
        throw Exception('无法获取用户信息');
      }
      await ApiService.changePassword(
        id: _user!.id,
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        Navigator.pop(context); // 关闭修改密码对话框
        _clearPasswordFields();
        Flushbar(
          title: '成功',
          message: '密码修改成功',
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
          titleColor: Colors.white,
          messageColor: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        ).show(context);
      }
    } catch (e) {
      if (mounted) {
        Flushbar(
          title: '修改失败',
          message: e.toString(),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          titleColor: Colors.white,
          messageColor: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  void _clearPasswordFields() {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageHelper.clearAll();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    _clearPasswordFields();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              const Text('修改密码', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Form(
            key: _passwordFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPasswordTextField(
                  controller: _oldPasswordController,
                  label: '当前密码',
                  obscureText: !_showOldPassword,
                  toggleVisibility: () => setDialogState(() => _showOldPassword = !_showOldPassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '请输入当前密码';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildPasswordTextField(
                  controller: _newPasswordController,
                  label: '新密码',
                  obscureText: !_showNewPassword,
                  toggleVisibility: () => setDialogState(() => _showNewPassword = !_showNewPassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '请输入新密码';
                    if (value.length < 6) return '密码长度至少6位';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildPasswordTextField(
                  controller: _confirmPasswordController,
                  label: '确认新密码',
                  obscureText: !_showConfirmPassword,
                  toggleVisibility: () => setDialogState(() => _showConfirmPassword = !_showConfirmPassword),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '请确认新密码';
                    if (value != _newPasswordController.text) return '两次输入的密码不一致';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isChangingPassword ? null : () => Navigator.pop(context),
              child: Text('取消', style: TextStyle(color: Colors.grey.shade700)),
            ),
            ElevatedButton(
              onPressed: _isChangingPassword ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isChangingPassword
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('确认修改'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback toggleVisibility,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: toggleVisibility,
          icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildUserInfoCard() {
    if (_user == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://cdn.jsdelivr.net/gh/yon3/static@main/avatar.png'),
            ),
            const SizedBox(height: 16),
            Text(
              _user!.username,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _user!.email,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text(
                _user!.role == 'ADMIN' ? '管理员' : '普通用户',
                style: TextStyle(color: _user!.role == 'ADMIN' ? Colors.red.shade800 : Colors.blue.shade800, fontWeight: FontWeight.bold),
              ),
              backgroundColor: _user!.role == 'ADMIN' ? Colors.red.shade50 : Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.card_membership_rounded, '证书数量', _user!.certificateCount.toString(), Colors.orange.shade600),
                _buildStatItem(Icons.event_available_rounded, '注册于', _formatDate(_user!.createdAt), Colors.green.shade600),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 36, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '编辑个人信息',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return '请输入用户名';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '邮箱',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return '请输入邮箱';
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) return '请输入有效的邮箱地址';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _usernameController.text = _user!.username;
                          _emailController.text = _user!.email;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUpdating ? null : _updateUserInfo,
                      icon: _isUpdating
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: const Text('保存'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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

  Widget _buildActionButtons() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            _buildActionButton(
              icon: Icons.edit_note_rounded,
              text: '编辑个人信息',
              onTap: () => setState(() => _isEditing = true),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildActionButton(
              icon: Icons.lock_reset_rounded,
              text: '修改密码',
              onTap: _showChangePasswordDialog,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildActionButton(
              icon: Icons.logout_rounded,
              text: '退出登录',
              onTap: _logout,
              color: Colors.red.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String text, required VoidCallback onTap, Color? color}) {
    final primaryColor = Theme.of(context).primaryColor;
    return ListTile(
      leading: Icon(icon, color: color ?? primaryColor),
      title: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 16)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('个人中心'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _loadUserInfo,
              icon: Icon(Icons.refresh_rounded, color: Theme.of(context).primaryColor),
              tooltip: '刷新',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: SpinKitFadingCube(
                color: Theme.of(context).primaryColor,
                size: 50.0,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildUserInfoCard(),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: _isEditing
                        ? _buildEditForm()
                        : _buildActionButtons(),
                  ),
                ],
              ),
            ),
    );
  }
}