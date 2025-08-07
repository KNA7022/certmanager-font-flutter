import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          // 登录成功，显示成功消息
          GFToast.showToast(
            result['message'] ?? '登录成功',
            context,
            toastPosition: GFToastPosition.BOTTOM,
            textStyle: const TextStyle(color: Colors.white, fontSize: 16),
            backgroundColor: Colors.green,
            trailing: const Icon(Icons.check_circle_outline, color: Colors.white),
          );

          // 跳转到主页
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          }
        } else {
          // 登录失败，显示错误消息
          GFToast.showToast(
            result['message'] ?? '登录失败',
            context,
            toastPosition: GFToastPosition.BOTTOM,
            textStyle: const TextStyle(color: Colors.white, fontSize: 16),
            backgroundColor: Colors.redAccent,
            trailing: const Icon(Icons.error_outline, color: Colors.white),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        GFToast.showToast(
          '登录过程中发生错误: $e',
          context,
          toastPosition: GFToastPosition.BOTTOM,
          textStyle: const TextStyle(color: Colors.white, fontSize: 16),
          backgroundColor: Colors.redAccent,
          trailing: const Icon(Icons.error_outline, color: Colors.white),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo和标题
                Center(
                  child: Column(
                    children: [
                      GFAvatar(
                        backgroundColor: GFColors.PRIMARY,
                        radius: 40,
                        child: const Icon(
                          Icons.verified_user,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '证书管理系统',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: GFColors.DARK,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '欢迎回来，请登录您的账户',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // 用户名输入框
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    hintText: '请输入用户名',
                    prefixIcon: const Icon(Icons.person_outline, color: GFColors.PRIMARY),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入用户名';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 密码输入框
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '密码',
                    hintText: '请输入密码',
                    prefixIcon: const Icon(Icons.lock_outline, color: GFColors.PRIMARY),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    if (value.length < 6) {
                      return '密码长度至少6位';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // 登录按钮
                SizedBox(
                  height: 50,
                  child: GFButton(
                    onPressed: _isLoading ? null : _login,
                    text: _isLoading ? '登录中...' : '登录',
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: GFButtonShape.pills,
                    type: GFButtonType.solid,
                    color: GFColors.PRIMARY,
                    fullWidthButton: true,
                    icon: _isLoading
                        ? const SpinKitFadingCube(
                            color: Colors.white,
                            size: 24.0,
                          )
                        : const Icon(Icons.login, color: Colors.white),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 注册链接
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '没有账户?',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        '立即注册',
                        style: TextStyle(
                          color: GFColors.PRIMARY,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // 底部信息
                Center(
                  child: Text(
                    '© 2024 证书管理系统',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}