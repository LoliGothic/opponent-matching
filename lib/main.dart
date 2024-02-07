import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';
import 'position.dart';
import 'database.dart';
import 'image.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = DataService(); //データベースのクラス

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ListView.builder(
              itemCount: _articles.length,
              itemBuilder: (BuildContext context, int index) {
                final item = _articles[index];
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
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text("${item.author} · ${item.postedOn}",
                              style: Theme.of(context).textTheme.caption),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icons.bookmark_border_rounded,
                              Icons.share,
                              Icons.more_vert
                            ].map((e) {
                              return InkWell(
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Icon(e, size: 16),
                                ),
                              );
                            }).toList(),
                          )
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
                                image: NetworkImage(item.imageUrl),
                              ))),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (_) {
                return const AlertDialogSample();
              });
          },
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      ),
    );
  }
}

class AlertDialogSample extends StatelessWidget {
  const AlertDialogSample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = DataService(); //データベースのクラス
    var contentController = TextEditingController();
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
        maxLines: null,
        decoration: const InputDecoration(
          labelText: "備考",
          // hintText: "Some Hint"
        ),         
      ),
      actions: <Widget>[
        FloatingActionButton.extended(
          onPressed: () {  
            getImageFromCamera();
          },
          icon: const Icon(Icons.add),
          label: const Text("写真を追加する"), 
          ),
        FloatingActionButton.extended(
          onPressed: () async {
            // データベースに登録
            Position position = await determinePosition();
            GeoPoint coordinate = GeoPoint(position.latitude, position.longitude);
            service.addPost(title, contentController.text, coordinate, "https://firebasestorage.googleapis.com/v0/b/opponent-matching.appspot.com/o/images%2Fgaryu.jpg?alt=media&token=57609fd0-1867-4279-8c4e-01c249d351ce");
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

class Article {
  final String title;
  final String imageUrl;
  final String author;
  final String postedOn;

  Article(
      {required this.title,
      required this.imageUrl,
      required this.author,
      required this.postedOn});
}

final List<Article> _articles = [
  Article(
    title: "デュエマ",
    author: "MacRumors",
    imageUrl: "https://firebasestorage.googleapis.com/v0/b/opponent-matching.appspot.com/o/images%2Fgaryu.jpg?alt=media&token=57609fd0-1867-4279-8c4e-01c249d351ce",
    postedOn: "Yesterday",
  ),
  Article(
      title: "ポケカ",
      imageUrl: "",
      author: "9to5Google",
      postedOn: "4 hours ago"),
  Article(
    title: "シャドバ",
    author: "New York Times",
    imageUrl: "https://pbs.twimg.com/media/F_dSvkca0AA0hWq?format=jpg&name=900x900",
    postedOn: "2 days ago",
  ),
  Article(
    title:
        "Amazon’s incredibly popular Lost Ark MMO is ‘at capacity’ in central Europe",
    author: "MacRumors",
    imageUrl: "https://picsum.photos/id/1002/960/540",
    postedOn: "22 hours ago",
  ),
  Article(
    title:
        "Panasonic's 25-megapixel GH6 is the highest resolution Micro Four Thirds camera yet",
    author: "Polygon",
    imageUrl: "https://picsum.photos/id/1020/960/540",
    postedOn: "2 hours ago",
  ),
  Article(
    title: "Samsung Galaxy S22 Ultra charges strangely slowly",
    author: "TechRadar",
    imageUrl: "https://picsum.photos/id/1021/960/540",
    postedOn: "10 days ago",
  ),
  Article(
    title: "Snapchat unveils real-time location sharing",
    author: "Fox Business",
    imageUrl: "https://picsum.photos/id/1060/960/540",
    postedOn: "10 hours ago",
  ),
];