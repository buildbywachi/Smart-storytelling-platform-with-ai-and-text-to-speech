import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryService {
  static final CollectionReference _historyCollection = FirebaseFirestore
      .instance
      .collection('history');

  static String _requireUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");
    return uid;
  }

  static Future<void> saveStory(String title, String content) async {
    try {
      final uid = _requireUid();

      await _historyCollection.add({
        "uid": uid,
        "title": title,
        "content": content,
        "createdAt": FieldValue.serverTimestamp(),
      });

      print("บันทึกประวัติลง Firebase สำเร็จ");
    } catch (e) {
      print("Error บันทึกไม่สำเร็จ: $e");
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final uid = _requireUid();

      final snapshot = await _historyCollection
          .where("uid", isEqualTo: uid)
          .orderBy("createdAt", descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // แปลง Timestamp เป็น DateTime
        final Timestamp ts = data["createdAt"];
        final DateTime dateTime = ts.toDate();

        data["createdAt"] = dateTime;
        data["id"] = doc.id;

        return data;
      }).toList();
    } catch (e) {
      print("Error ดึงข้อมูลไม่สำเร็จ: $e");
      return [];
    }
  }

  // 3. ฟังก์ชันลบรายการเดียว (Delete One)
  static Future<void> deleteStory(String docId) async {
    try {
      await _historyCollection.doc(docId).delete();
      print("ลบรายการสำเร็จ: $docId");
    } catch (e) {
      print("Error ลบรายการไม่สำเร็จ: $e");
      rethrow;
    }
  }
}
