import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future getImageFromCamera() async {
  File? image;
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.camera);

  if (pickedFile != null){
    print("aa");
    image = File(pickedFile.path);
    final storageRef = FirebaseStorage.instance.ref("/images").child("/garyu.jpg");
    final task = await storageRef.putFile(image);
    print(await storageRef.getDownloadURL());
  }
  else {
    print("画像が撮影されませんでした．");
  }
 }
