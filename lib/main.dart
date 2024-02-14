import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admob_flutter/admob_flutter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';
import 'position.dart';
import 'database.dart';
import 'image.dart';
import 'services/admob.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Admob.initialize();
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MyPage();
  }
}

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  State<MyPage> createState() => _MyPage();
}

class _MyPage extends State<MyPage>{
  QuerySnapshot? querySnapshotPosts;
  List posts = [];
  final service = DataService(); //データベースのクラス

  Future<void> getPost2List() async {
    querySnapshotPosts = await service.getPost();
    Position position = await determinePosition();
    posts.clear();
    setState(() {
      if (querySnapshotPosts != null){
        //firestoreから来たデータを，扱いやすいようにmapが集まった，listにする
        List tmpPosts = querySnapshotPosts!.docs.map((doc) => doc.data()).toList();
        double distanceInMeters = 50;
        for (Map<String, dynamic> tmpPost in tmpPosts){
          if (distanceInMeters >= Geolocator.distanceBetween(position.latitude, position.longitude, tmpPost["coordinate"].latitude, tmpPost["coordinate"].longitude)) {
            posts.add(tmpPost);
          }
        }
      }
      else {
        posts.clear();
      }
    });
  }

  String getDiffDate(DateTime start, DateTime end) {
  var dif = end.difference(start).inSeconds;

  var hour = dif ~/ 60 ~/ 60;
  var min = dif ~/ 60 % 60;
  var sec = dif % 60;
  return '$hour時間 $min分 $sec秒前';
  }

  @override
  void initState() {
    super.initState();
    // initState自体ではasync出来ないので，一度Futureに入れる
    getPost2List();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: RefreshIndicator(
            onRefresh: () async {
              getPost2List();
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: posts.isNotEmpty ? ListView.builder(
                itemCount: posts.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = posts[index];
                  return Container(
                    height: 136,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8.0)),
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["title"],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              getDiffDate(item["createdAt"].toDate(), DateTime.now()),
                              style: Theme.of(context).textTheme.bodySmall!.merge(
                                const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(item["content"],
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 8),
                          ],
                        )),
                        Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(8.0),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(item["imageUrl"]),
                                ))),
                      ],
                    ),
                  );
                },
              ) : ListView(), //何もないときもスクロールで更新できるように，空のListViewを追加
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (_) {
                return AlertDialogSample(getPost2List: getPost2List);
              });
          },
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          AdmobBanner(
            adUnitId: AdMobService().getBannerAdUnitId(),
            adSize: AdmobBannerSize(
              width: MediaQuery.of(context).size.width.toInt(),
              height: AdMobService().getHeight(context).toInt(),
              name: 'SMART_BANNER',
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class AlertDialogSample extends StatelessWidget {
  final VoidCallback getPost2List;
  const AlertDialogSample({Key? key, required this.getPost2List}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = DataService(); //データベースのクラス
    var contentController = TextEditingController();
    File? image;
    String imageUrl = "https://www.shoshinsha-design.com/wp-content/uploads/2020/05/noimage-760x460.png";
    String title = "ポケカ";

    return AlertDialog(
      title: DropdownButtonMenu(
        onValueChanged: (value) {
          title = value;
        },
      ),
      content: TextField(
        keyboardType: TextInputType.multiline,
        controller: contentController,
        maxLines: 3,
        maxLength: 100,
        decoration: const InputDecoration(
          labelText: "備考",
        ),         
      ),
      actions: <Widget>[
        FloatingActionButton.extended(
          onPressed: () async {  
            image = await getImageFromCamera();
          },
          icon: const Icon(Icons.add),
          label: const Text("写真を追加する"), 
          ),
        FloatingActionButton.extended(
          onPressed: () async {
            // ロード画面が表示
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
            
            // データベースに登録
            Position position = await determinePosition();
            GeoPoint coordinate = GeoPoint(position.latitude, position.longitude);

            // 画像が登録されてる時は，画像をStorageに保存して，URLを取ってくる
            if (image != null){
              imageUrl = await registerImage4Storage(image!); 
            }

            // 投稿内容をfirestoreに登録
            service.addPost(title, contentController.text, coordinate, imageUrl);

            getPost2List();
            
            // 非同期の中でcontextを使うときの対策
            if (!context.mounted) return;
            // ロード画面とアラートダイアログを消す
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          label: const Text("投稿"),
        ),
      ],
    );
  }
}

class DropdownButtonMenu extends StatefulWidget {
  final void Function(String)? onValueChanged;
  const DropdownButtonMenu({Key? key, this.onValueChanged}) : super(key: key);

  @override
  State<DropdownButtonMenu> createState() => _DropdownButtonMenuState();
}

class _DropdownButtonMenuState extends State<DropdownButtonMenu> {
  String isSelectedValue = 'ポケカ';

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      decoration: const InputDecoration(
        labelText: "タイトルの選択"
      ),
      items: const[
        DropdownMenuItem(
          value: 'ポケカ',
          child: Text('ポケカ'),
        ),
        DropdownMenuItem(
            value: 'デュエマ',
            child: Text('デュエマ'),
        ),
        DropdownMenuItem(
            value: '遊戯王',
            child: Text('遊戯王'),
        ),
        DropdownMenuItem(
            value: 'MTG',
            child: Text('MTG'),
        ),
        DropdownMenuItem(
            value: 'ヴァンガード',
            child: Text('ヴァンガード'),
        ),
      ],
      value: isSelectedValue,
      onChanged: (String? value) {
        setState(() {
          isSelectedValue = value!;
          widget.onValueChanged?.call(isSelectedValue);
        });
      },
    );
  }
}