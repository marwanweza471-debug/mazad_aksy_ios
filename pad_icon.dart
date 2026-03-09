import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/app_icon.png');
  final original = img.decodeImage(file.readAsBytesSync());
  if (original == null) {
      print('Failed to decode image');
      return;
  }
  
  // Create a 40% larger canvas
  final w = (original.width * 1.4).toInt();
  final h = (original.height * 1.4).toInt();
  
  final canvas = img.Image(width: w, height: h, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));
  
  final dstX = (w - original.width) ~/ 2;
  final dstY = (h - original.height) ~/ 2;
  
  img.compositeImage(canvas, original, dstX: dstX, dstY: dstY);
  
  File('assets/app_icon_padded.png').writeAsBytesSync(img.encodePng(canvas));
  print('Done.');
}
