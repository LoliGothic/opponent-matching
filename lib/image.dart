import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

Future getImageFromCamera() async {
  File? image;
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.camera);

  if (pickedFile != null){
    image = File(pickedFile.path);

    return image;
  }
  else {
    return 0;
  }
 }

 Future registerImage4Storage(File image) async {
  const uuid = Uuid();

  String newUuid = uuid.v4();
  final storageRef = FirebaseStorage.instance.ref("/images").child("/$newUuid.jpg");
  await storageRef.putFile(image);

  return await storageRef.getDownloadURL();
 }
// urlからpathを取得できる
// storageRef = FirebaseStorage.instance.refFromURL(url)

Future deleteImage4Storage(String imageUrl) async {
final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
await storageRef.delete();
}