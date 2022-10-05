import 'package:supabase/supabase.dart';

class SupaBase {
  final SupabaseClient client = SupabaseClient(
    'https://oexssbhsqxsnailmuamp.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9leHNzYmhzcXhzbmFpbG11YW1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NjQ5Nzc2NTksImV4cCI6MTk4MDU1MzY1OX0.smuxSYHQkUk85gJqR7OHkE5lEMRz-E2r8vlyenHde5c',
  );

  Future<Map> getUpdate() async {
    final response =
        await client.from('Update').select().order('LatestVersion').execute();
    final List result = response.data as List;
    return result.isEmpty
        ? {}
        : {
            'LatestVersion': response.data[0]['LatestVersion'],
            'LatestUrl': response.data[0]['LatestUrl'],
            'arm64-v8a': response.data[0]['arm64-v8a'],
            'armeabi-v7a': response.data[0]['armeabi-v7a'],
            'universal': response.data[0]['universal'],
          };
  }

  Future<void> updateUserDetails(
    String? userId,
    String key,
    dynamic value,
  ) async {
    // final response = await client.from('Users').update({key: value},
    //     returning: ReturningOption.minimal).match({'id': userId}).execute();
    // print(response.toJson());
  }

  Future<int> createUser(Map data) async {
    final response = await client
        .from('Users')
        .insert(data, returning: ReturningOption.minimal)
        .execute();
    return response.status ?? 404;
  }
}
