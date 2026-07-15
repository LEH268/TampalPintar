import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import '../lib/helpers.dart';

void main() {
  test('project reachable with anon key', () async {
    final env = await TestEnv.load();
    // auth health endpoint needs no tables; proves URL + anon key are valid
    final res = await http.get(
      Uri.parse('${env.url}/auth/v1/health'),
      headers: {'apikey': env.anonKey},
    );
    expect(res.statusCode, 200, reason: res.body);
    env.admin.dispose();
  });
}
