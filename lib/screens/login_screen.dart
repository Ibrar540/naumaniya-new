import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/offline_auth_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _institutionController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isFirstLogin = true;
  String? storedEmail;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        storedEmail = prefs.getString('email');
        isFirstLogin = storedEmail == null;
        if (!isFirstLogin) {
          _emailController.text = storedEmail!;
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _institutionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _isOffline() async {
    final connectivity = await Connectivity().checkConnectivity();
    return connectivity == ConnectivityResult.none;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        bool offline = await _isOffline();
        if (offline) {
          // Try offline login
          bool ok = await OfflineAuthService.tryOfflineLogin(
            _emailController.text,
            _passwordController.text,
          );
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Logged in offline. Some features may be unavailable.'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } else {
            setState(() { _error = 'Offline login failed. Please check your credentials or connect to the internet.'; });
          }
        } else {
          // Online login
          final error = await AuthService().login(
            email: isFirstLogin ? _emailController.text : null,
            password: _passwordController.text,
          );
          if (error != null) {
            setState(() { _error = error; });
          } else {
            // Save credentials for offline login
            await OfflineAuthService.saveCredentials(
              _emailController.text,
              _passwordController.text,
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
        }
      } else {
        // Create account
        final error = await AuthService().createAccount(
          fullName: _nameController.text,
          email: _emailController.text,
          institutionName: _institutionController.text,
          password: _passwordController.text,
        );
        if (error != null) {
          setState(() { _error = error; });
        } else {
          setState(() {
            _isLogin = true;
            _nameController.clear();
            _emailController.clear();
            _institutionController.clear();
            _passwordController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account created successfully! Please login.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Responsive Header
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    style: TextStyle(
                      fontSize: isMobile ? 28 : (isTablet ? 30 : 32),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  Text(
                    _isLogin 
                      ? 'Login with your password' 
                      : 'Sign up to get started',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18, 
                      color: Colors.white70
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 32 : 40),

                  // Responsive Form Container
                  Container(
                    width: isMobile ? double.infinity : (isTablet ? 500 : 600),
                    padding: EdgeInsets.all(isMobile ? 20 : 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Form Fields
                        if (!_isLogin) ...[
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Name',
                            icon: Icons.person,
                            isMobile: isMobile,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isMobile ? 16 : 20),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            isMobile: isMobile,
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isMobile ? 16 : 20),
                          _buildTextField(
                            controller: _institutionController,
                            hint: 'Institution Name',
                            icon: Icons.school,
                            isMobile: isMobile,
                             validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your institution name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isMobile ? 16 : 20),
                        ],
                        
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: Icons.lock,
                          isPassword: true,
                          isMobile: isMobile,
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        if (_error != null) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 16 : 20),
                        ],

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: isMobile ? 48 : 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                              ),
                              elevation: 2,
                            ),
                            child: _loading
                              ? SizedBox(
                                  width: isMobile ? 20 : 24,
                                  height: isMobile ? 20 : 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Login' : 'Create Account',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 20 : 24),

                        // Toggle Button
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _error = null;
                            });
                          },
                          child: Text(
                            _isLogin 
                              ? 'Don\'t have an account? Create one' 
                              : 'Already have an account? Login',
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isMobile = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: isMobile ? 16 : 18),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: isMobile ? 16 : 18,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey[600],
          size: isMobile ? 20 : 24,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: isMobile ? 16 : 20,
        ),
      ),
    );
  }
} 