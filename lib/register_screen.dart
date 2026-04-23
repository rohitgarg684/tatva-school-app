import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'teacher_dashboard.dart';
import 'parent_dashboard.dart';
import 'student_dashboard.dart';
import 'principal_dashboard.dart';
import 'firestore_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _classCodeController = TextEditingController();
  final _childNameController = TextEditingController();

  String _selectedRole = 'Student';
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final List<Map<String, dynamic>> _roles = [
    {
      'label': 'Student',
      'icon': Icons.school_outlined,
      'desc': 'I am a student'
    },
    {
      'label': 'Parent',
      'icon': Icons.family_restroom_outlined,
      'desc': 'I am a parent'
    },
    {
      'label': 'Teacher',
      'icon': Icons.person_outlined,
      'desc': 'I teach classes'
    },
    {
      'label': 'Principal',
      'icon': Icons.business_outlined,
      'desc': 'I manage the school'
    },
  ];

  static const Color bg = Color(0xFFF4F9F4);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF2E6B4F);
  static const Color accent = Color(0xFFE8A020);
  static const Color textDark = Color(0xFF1A2E22);
  static const Color textMid = Color(0xFF4A6B55);
  static const Color textLight = Color(0xFF8FAF8F);
  static const Color danger = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _slideController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _slideController, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 100), () {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _classCodeController.dispose();
    _childNameController.dispose();
    super.dispose();
  }

  Color get _roleColor {
    switch (_selectedRole) {
      case 'Teacher':
        return accent;
      case 'Principal':
        return Color(0xFF8E24AA);
      case 'Parent':
        return success;
      default:
        return Color(0xFF1E88E5);
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final classCode = _classCodeController.text.trim().toUpperCase();
    final childName = _childNameController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all required fields.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if ((_selectedRole == 'Student' || _selectedRole == 'Parent') &&
        classCode.isEmpty) {
      setState(() =>
          _errorMessage = 'Please enter a class code to join your class.');
      return;
    }
    if (_selectedRole == 'Parent' && childName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your child\'s name.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 1. Create Firebase Auth user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      // 2. Save user to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': _selectedRole,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'classIds': [],
        if (_selectedRole == 'Parent') 'children': [],
      });

      // 3. Join class (Student or Parent)
      if (_selectedRole == 'Student' || _selectedRole == 'Parent') {
        final fs = FirestoreService();
        final error = await fs.joinClassByCode(
          classCode: classCode,
          role: _selectedRole,
          childName: _selectedRole == 'Parent' ? childName : null,
        );

        if (error != null) {
          // Class code failed — still registered but not in a class
          // Show warning but continue to dashboard
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Registered! But class code invalid: $error You can add a class later.',
                  style: TextStyle(fontFamily: 'Raleway')),
              backgroundColor: accent,
              duration: Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          }
        }
      }

      // 4. Navigate to correct dashboard
      if (mounted) {
        Widget dashboard;
        switch (_selectedRole) {
          case 'Teacher':
            dashboard = TeacherDashboard();
            break;
          case 'Parent':
            dashboard = ParentDashboard();
            break;
          case 'Principal':
            dashboard = PrincipalDashboard();
            break;
          default:
            dashboard = StudentDashboard();
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => dashboard),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'This email is already registered. Try logging in.';
          break;
        case 'invalid-email':
          msg = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          msg = 'Password is too weak. Use at least 6 characters.';
          break;
        default:
          msg = e.message ?? 'Registration failed. Please try again.';
      }
      setState(() {
        _errorMessage = msg;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12),

                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: Icon(Icons.arrow_back_rounded,
                          color: textDark, size: 20),
                    ),
                  ),
                  SizedBox(height: 28),

                  // Header
                  Row(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [primary, Color(0xFF3D8B6B)]),
                          borderRadius: BorderRadius.circular(14)),
                      child: Center(
                          child: Text('T',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white))),
                    ),
                    SizedBox(width: 14),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create Account',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                  letterSpacing: -0.5)),
                          Text('Join Tatva Academy',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 14,
                                  color: textLight)),
                        ]),
                  ]),
                  SizedBox(height: 32),

                  // Role selector
                  Text('I am a...',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark)),
                  SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.5),
                    itemCount: _roles.length,
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      final isSelected = _selectedRole == role['label'];
                      final rColor = _getRoleColor(role['label']);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedRole = role['label'];
                            _errorMessage = null;
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                              color:
                                  isSelected ? rColor.withOpacity(0.1) : bgCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: isSelected
                                      ? rColor
                                      : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1)),
                          child: Row(children: [
                            Icon(role['icon'] as IconData,
                                color: isSelected ? rColor : textLight,
                                size: 18),
                            SizedBox(width: 8),
                            Text(role['label'],
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected ? rColor : textMid)),
                          ]),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 24),

                  // Form fields
                  _inputLabel('Full Name'),
                  SizedBox(height: 8),
                  _textField(
                    controller: _nameController,
                    hint: 'Enter your full name',
                    icon: Icons.person_outline_rounded,
                  ),
                  SizedBox(height: 14),

                  _inputLabel('Email Address'),
                  SizedBox(height: 8),
                  _textField(
                    controller: _emailController,
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 14),

                  _inputLabel('Password'),
                  SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: InputDecoration(
                      hintText: 'At least 6 characters',
                      hintStyle: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 13,
                          color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.lock_outline_rounded,
                          color: textLight, size: 20),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        child: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: textLight,
                            size: 20),
                      ),
                      filled: true,
                      fillColor: bgCard,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: _roleColor.withOpacity(0.5), width: 1.5)),
                    ),
                  ),

                  // Class code field (Student or Parent)
                  if (_selectedRole == 'Student' ||
                      _selectedRole == 'Parent') ...[
                    SizedBox(height: 14),
                    if (_selectedRole == 'Parent') ...[
                      _inputLabel("Child's Name"),
                      SizedBox(height: 8),
                      _textField(
                        controller: _childNameController,
                        hint: "Enter your child's full name",
                        icon: Icons.child_care_outlined,
                      ),
                      SizedBox(height: 14),
                    ],
                    _inputLabel('Class Code'),
                    SizedBox(height: 4),
                    Text(
                        _selectedRole == 'Student'
                            ? 'Get this from your teacher'
                            : "Get this from your child's teacher",
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            color: textLight)),
                    SizedBox(height: 8),
                    TextField(
                      controller: _classCodeController,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 18,
                          color: textDark,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4),
                      decoration: InputDecoration(
                        hintText: 'e.g. MATH123',
                        hintStyle: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            color: Colors.grey.shade400,
                            letterSpacing: 1,
                            fontWeight: FontWeight.normal),
                        prefixIcon: Icon(Icons.key_outlined,
                            color: textLight, size: 20),
                        filled: true,
                        fillColor: bgCard,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: _roleColor.withOpacity(0.5),
                                width: 1.5)),
                      ),
                    ),
                  ],

                  // Teacher note (no class code needed)
                  if (_selectedRole == 'Teacher') ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: accent.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accent.withOpacity(0.2))),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded,
                            color: accent, size: 16),
                        SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                'After registering, create a class to get your class code.',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: textMid,
                                    height: 1.5))),
                      ]),
                    ),
                  ],

                  // Principal note
                  if (_selectedRole == 'Principal') ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Color(0xFF8E24AA).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Color(0xFF8E24AA).withOpacity(0.2))),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded,
                            color: Color(0xFF8E24AA), size: 16),
                        SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                'Principal accounts have full school access and can manage all teachers and parents.',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: textMid,
                                    height: 1.5))),
                      ]),
                    ),
                  ],

                  // Error message
                  if (_errorMessage != null) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: danger.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: danger.withOpacity(0.2))),
                      child: Row(children: [
                        Icon(Icons.error_outline_rounded,
                            color: danger, size: 16),
                        SizedBox(width: 10),
                        Expanded(
                            child: Text(_errorMessage!,
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: danger,
                                    height: 1.4))),
                      ]),
                    ),
                  ],

                  SizedBox(height: 28),

                  // Register button
                  GestureDetector(
                    onTap: _loading ? null : _register,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                          color: _loading
                              ? _roleColor.withOpacity(0.5)
                              : _roleColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _loading
                              ? []
                              : [
                                  BoxShadow(
                                      color: _roleColor.withOpacity(0.35),
                                      blurRadius: 16,
                                      offset: Offset(0, 6))
                                ]),
                      child: Center(
                          child: _loading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text('Create Account',
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.3))),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Login link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => LoginScreen())),
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 14,
                                  color: textLight)),
                          TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 14,
                                  color: _roleColor,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────
  Color _getRoleColor(String role) {
    switch (role) {
      case 'Teacher':
        return accent;
      case 'Principal':
        return Color(0xFF8E24AA);
      case 'Parent':
        return success;
      default:
        return Color(0xFF1E88E5);
    }
  }

  Widget _inputLabel(String label) => Text(label,
      style: TextStyle(
          fontFamily: 'Raleway',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textDark));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontFamily: 'Raleway', fontSize: 14, color: textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              fontFamily: 'Raleway', fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: textLight, size: 20),
          filled: true,
          fillColor: bgCard,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: _roleColor.withOpacity(0.5), width: 1.5)),
        ),
      );
}
