import 'package:cloud_firestore/cloud_firestore.dart';

// データベースへの書き込みを行うクラス
class DataService {
  // データベースの参照を取得
  final db = FirebaseFirestore.instance;
  // データベースにデータを追加
  Future<void> addPost(String title, String content, GeoPoint coordinate, String imagePath) {
    return db.collection('posts').add({
      'title': title,
      'content': content,
      'coordinate': coordinate,
      'imagePath': imagePath,
      'createdAt': Timestamp.now(),
    });
  }
}