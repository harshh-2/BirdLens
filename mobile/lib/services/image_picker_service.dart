import 'package:image_picker/image_picker.dart';

class ImagePickerService {

  static final ImagePicker _picker =
      ImagePicker();

  static Future<XFile?>
      pickFromCamera() async {

    return await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
  }

  static Future<XFile?>
      pickFromGallery() async {

    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }
}