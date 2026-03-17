import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // import ปกติ
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(); 

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _emailLogin() async {
    
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("กรุณากรอกข้อมูล"))); return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(), password: _passwordController.text.trim());
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

 
  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      // 1. Trigger Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Obtain the auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, 
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                   const Icon(Icons.auto_stories, size: 80, color: Colors.deepPurple),
                   const SizedBox(height: 20),
                   const Text("Thai Story AI", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 30),
                   TextField(controller: _emailController, decoration: const InputDecoration(labelText: "อีเมล", border: OutlineInputBorder())),
                   const SizedBox(height: 15),
                   TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "รหัสผ่าน", border: OutlineInputBorder()), obscureText: true),
                   const SizedBox(height: 25),
                   if (_isLoading) const CircularProgressIndicator() else Column(
                     children: [
                       SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _emailLogin, style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text("เข้าสู่ระบบ"))),
                       const SizedBox(height: 15),
                       const Divider(),
                       const SizedBox(height: 15),
                       SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _googleLogin, icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red), label: const Text("เข้าสู่ระบบด้วย Google"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)))),
                       const SizedBox(height: 15),
                       TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text("สมัครสมาชิกใหม่")),
                     ],
                   )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}