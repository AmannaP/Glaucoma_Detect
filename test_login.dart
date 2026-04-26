import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final response = await http.post(
    Uri.parse('http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/auth.php?action=login'),
    body: json.encode({
      "email": "alice.green@glaucoma.com",
      "password": "doctor123",
    }),
  );
  print(response.body);
}
