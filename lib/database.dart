import 'package:cloud_firestore/cloud_firestore.dart';

// データベースへの書き込みを行うクラス
class DataService {
  // データベースの参照を取得
  final db = FirebaseFirestore.instance;
  // データベースにデータを追加
  Future<void> addPost(String title, String content, GeoPoint coordinate, String imageUrl) {
    return db.collection('posts').add({
      'title': title,
      'content': content,
      'coordinate': coordinate,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.now(),
    });
  }

  Future getPost() {
    return db.collection('posts').orderBy('createdAt', descending: true).get();
  }

  Future<void> deletePost() async {
    DateTime tmpSixHoursAgo = DateTime.now().subtract(const Duration(minutes: 1)); //6時間前の時刻を取得
    Timestamp sixHoursAgo = Timestamp.fromDate(tmpSixHoursAgo); //timestamp型に変更
    QuerySnapshot snapshot = await db.collection('posts').where('createdAt', isLessThan: sixHoursAgo).get(); //全てを取得
    
    for (QueryDocumentSnapshot doc in snapshot.docs){
      await doc.reference.delete();
    }
  }
}