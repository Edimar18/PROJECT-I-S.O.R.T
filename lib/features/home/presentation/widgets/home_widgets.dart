
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.recycling, color: Color(0xFF2E7D32), size: 50),
        const SizedBox(height: 24),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
            children: [
              TextSpan(text: 'Andam Na Ba Ka, \n'),
              TextSpan(
                text: 'Higala?',
                style: TextStyle(color: Color(0xFF2E7D32)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Log in to track your impact in CDO.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        TextFormField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            hintText: 'Email or Phone Number',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          obscureText: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            hintText: 'Password',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
            suffixIcon: Icon(Icons.visibility_off_outlined, color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Forgot Password?',
            style: TextStyle(color: Colors.green[700]),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1de9b6), // Teal accent
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        const Text('OR', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        RichText(
          text: TextSpan(
            style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
            children: <TextSpan>[
              const TextSpan(text: 'New to I-S.O.R.T.? '),
              TextSpan(
                text: 'Create Account',
                style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                recognizer: TapGestureRecognizer()..onTap = () {
                  // Navigate to account creation screen
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class OfficialPartnerSection extends StatelessWidget {
  const OfficialPartnerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/cedo.png',
            height: 30,
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OFFICIAL PARTNER',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,

                ),
              ),
              Text(
                'CITY EDUCATION DEVELOPMENT OFFFICE',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
