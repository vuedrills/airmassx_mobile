import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  await googleSignIn.signOut();
}
