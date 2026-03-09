import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // السطر ده هو الحل



class GlobalUser {
  static bool isPremium = false;

  // نده دي مرة واحدة في الـ initState بتاع أول صفحة أو بعد الـ Login
  static Future<void> updateStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      isPremium = doc.data()?['isPremium'] ?? false;
    } else {
      isPremium = false;
    }
  }
}