import 'dart:convert'; // ไว้แปลง Base64
import 'dart:typed_data'; // ไว้จัดการข้อมูลเสียง
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // ตัวเล่นเสียง
import '../services/api_service.dart';
import '../history_screen.dart';
import '../services/history_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _topicController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer(); // สร้างเครื่องเล่นเสียง

  String _resultStory = "";
  String? _audioBase64; // ตัวแปรเก็บรหัสเสียง
  bool _isLoading = false;
  bool _isPlaying = false; // เช็คว่าเสียงกำลังเล่นอยู่ไหม
  String _selectedVoice = "th-TH-PremwadeeNeural";

  @override
  void dispose() {
    _audioPlayer.dispose(); // ปิดเครื่องเล่นเมื่อออกจากหน้า
    super.dispose();
  }

  Future<void> _generate() async {
    if (_topicController.text.isEmpty) return;

    await _audioPlayer.stop();
    setState(() {
      _isLoading = true;
      _resultStory = "";
      _audioBase64 = null;
      _isPlaying = false;
    });

    final result = await ApiService.generateStory(
      _topicController.text,
      _selectedVoice,
    );

    setState(() {
      _resultStory = result['story'];
      _audioBase64 = result['audio'];
      _isLoading = false;
    });

    if (_resultStory.isNotEmpty && !_resultStory.startsWith("Error")) {
      await HistoryService.saveStory(_topicController.text, _resultStory);
    }
  }

  // ฟังก์ชันเล่นเสียง
  Future<void> _playAudio() async {
    if (_audioBase64 == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        // 1. แปลงรหัส Base64 เป็น Bytes (ข้อมูลดิบ)
        Uint8List audioBytes = base64Decode(_audioBase64!);

        // 2. สั่งเล่นจากข้อมูลดิบ (BytesSource)
        await _audioPlayer.play(BytesSource(audioBytes));
        setState(() => _isPlaying = true);

        // 3. เมื่อเล่นจบ ให้เปลี่ยนไอคอนกลับ
        _audioPlayer.onPlayerComplete.listen((event) {
          if (mounted) setState(() => _isPlaying = false);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เล่นเสียงไม่ได้: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI นักเล่านิทาน 🤖"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "อยากฟังนิทานเรื่องอะไร?",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                hintText: "เช่น ลูกหมูสามตัวผจญภัย...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedVoice,
              decoration: const InputDecoration(
                labelText: "เลือกเสียงผู้บรรยาย",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: "th-TH-PremwadeeNeural",
                  child: Text("เสียงผู้หญิง"),
                ),
                DropdownMenuItem(
                  value: "th-TH-NiwatNeural",
                  child: Text("เสียงผู้ชาย"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedVoice = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generate,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? "กำลังแต่งนิทาน..." : "เริ่มแต่งนิทาน"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // แสดงผลลัพธ์
            if (_resultStory.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.deepPurple.shade100),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade200, blurRadius: 10),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "📜 นิทานของคุณ",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),

                        // ปุ่มเล่นเสียง
                        if (_audioBase64 != null)
                          IconButton.filled(
                            onPressed: _playAudio,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.volume_up,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.deepPurple.shade100,
                              foregroundColor: Colors.deepPurple,
                            ),
                          ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      _resultStory,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
