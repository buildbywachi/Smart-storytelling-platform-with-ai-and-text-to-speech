import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _historyList = [];

  @override
  void initState() {
    super.initState();
    _loadHistory(); // โหลดข้อมูลทันทีที่เปิดหน้า
  }

  Future<void> _loadHistory() async {
    final list = await HistoryService.getHistory();
    setState(() {
      _historyList = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📜 ประวัตินิทาน"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _historyList.isEmpty
          ? const Center(
              child: Text(
                "ยังไม่มีประวัตินิทาน",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _historyList.length,
              itemBuilder: (context, index) {
                final item = _historyList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.book, color: Colors.white),
                    ),
                    title: Text(
                      item['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(item['createdAt']),
                    ),
                    onTap: () {
                      // กดแล้วเด้งหน้าต่างมาโชว์เนื้อหา
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(item['title']),
                          content: SingleChildScrollView(
                            child: Text(item['content']),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("ปิด"),
                            ),
                          ],
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final id = item['id'];
                        if (id == null) return;

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("ลบประวัติรายการนี้?"),
                            content: Text(
                              "คุณต้องการลบ “${item['title']}” ใช่หรือไม่",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("ยกเลิก"),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("ลบ"),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await HistoryService.deleteStory(id);
                          _loadHistory(); // โหลดใหม่หลังจากลบ
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
