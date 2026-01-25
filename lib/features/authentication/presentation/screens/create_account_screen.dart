
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:i_sort/features/authentication/services/auth_service.dart';
import 'package:i_sort/features/data/services/firestore_service.dart';
import 'package:intl/intl.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();

  String? _selectedBarangay;
  List<String> _barangays = [];
  bool _isLoading = false;
  bool _obscurePassword = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadBarangays();
  }

  Future<void> _loadBarangays() async {
    final barangays = await _firestoreService.getBarangays();
    setState(() {
      _barangays = barangays;
    });
  }

  void _createAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final error = await _authService.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
        dateOfBirth: _selectedDate!,
        address: _selectedBarangay!,
        contactNumber: _contactController.text,
      );
      setState(() => _isLoading = false);

      if (error == null && mounted) {
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'An unknown error occurred.')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('MMMM d, yyyy').format(picked);
        final age = DateTime.now().difference(picked).inDays ~/ 365;
        _ageController.text = age.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/cdo-background.png', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.5),
                  Colors.white.withOpacity(0.9),
                ],
                stops: const [0.15, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        _buildTextFormField(controller: _nicknameController, hintText: 'Nickname', icon: Icons.person_outline),
                        const SizedBox(height: 16),
                        _buildTextFormField(controller: _emailController, hintText: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        _buildPasswordFormField(),
                        const SizedBox(height: 16),
                        _buildDobField(),
                        const SizedBox(height: 16),
                        _buildTextFormField(controller: _ageController, hintText: 'Age', icon: Icons.cake_outlined, readOnly: true),
                        const SizedBox(height: 16),
                        _buildDropdown(),
                        const SizedBox(height: 16),
                        _buildTextFormField(controller: _contactController, hintText: 'Contact Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 24),
                        _isLoading ? const CircularProgressIndicator() : _buildSignUpButton(),
                        const SizedBox(height: 24),
                        _buildLoginLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({required TextEditingController controller, required String hintText, required IconData icon, bool readOnly = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hintText, icon),
      validator: (value) => value!.isEmpty ? 'Please enter your $hintText' : null,
    );
  }

  Widget _buildPasswordFormField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: _inputDecoration('Password', Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
    );
  }

  Widget _buildDobField() {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      decoration: _inputDecoration('Date of Birth', Icons.calendar_today_outlined),
      onTap: () => _selectDate(context),
      validator: (value) => value!.isEmpty ? 'Please select your date of birth' : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Address (Barangay)', Icons.home_outlined),
      value: _selectedBarangay,
      items: _barangays.map((barangay) => DropdownMenuItem(value: barangay, child: Text(barangay))).toList(),
      onChanged: (value) => setState(() => _selectedBarangay = value),
      validator: (value) => value == null ? 'Please select your barangay' : null,
    );
  }

  InputDecoration _inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[100],
      hintText: hintText,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _createAccount,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1de9b6),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLoginLink() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black54),
        children: <TextSpan>[
          const TextSpan(text: 'Already have an account? '),
          TextSpan(
            text: 'Login',
            style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()..onTap = () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
