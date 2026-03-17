// หน้าหลักหลังล็อกอินสำเร็จ
import 'package:thai_story_app/screens/create_story_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // import เพื่อใช้ google logout

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser; // ดึงข้อมูลคนล็อกอินมาโชว์

  // ฟังก์ชันออกจากระบบ
  Future<void> _signOut() async {
    // 1. ออกจาก Firebase
    await FirebaseAuth.instance.signOut();
    // 2. ออกจาก Google (เพื่อให้กดล็อกอินใหม่ได้เลือกบัญชีอื่นได้)
    await GoogleSignIn().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thai Story AI 📖"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          // ปุ่ม Logout มุมขวาบน
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: "ออกจากระบบ",
          )
        ],  
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // รูปโปรไฟล์ (ถ้ามี) หรือไอคอน
              CircleAvatar(
                radius: 40,
                backgroundImage: user?.photoURL != null 
                    ? NetworkImage(user!.photoURL!) 
                    : null,
                child: user?.photoURL == null 
                    ? const Icon(Icons.person, size: 40) 
                    : null,
              ),
              const SizedBox(height: 20),
              
              Text(
                "สวัสดี, ${user?.displayName ?? user?.email ?? 'นักเล่านิทาน'}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("พร้อมจะแต่งนิทานเรื่องใหม่หรือยัง?"),
              
              const SizedBox(height: 40),
              
              // ปุ่มเริ่มสร้างนิทาน 
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const CreateStoryScreen()),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text("✨ ให้ AI แต่งนิทาน", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}