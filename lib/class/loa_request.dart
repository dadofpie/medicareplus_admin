import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class ApiService {
  final String apiUrl;

  ApiService(this.apiUrl);

  Future<List<Map<String, dynamic>>> fetchAllMembers(String supabaseUrl, String supabaseKey) async {
    final response = await http.post(
      Uri.parse(apiUrl + '/api/admin/get_loa_request'),
      headers: {
        "supabase-url": supabaseUrl,
        "supabase-key": supabaseKey,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      // Ensure the type safety by converting to List<Map<String, dynamic>>
      return List<Map<String, dynamic>>.from(data['loa_request'] ?? []);
      
    } else {
      throw Exception('Failed to load loa');
    }
  }

  Stream<List<Map<String, dynamic>>> streamAllRequest(String supabaseUrl, String supabaseKey) async* {
    while (true) {
      try {
        final members = await fetchAllMembers(supabaseUrl, supabaseKey);
        yield members; // Emit the list of members
      } catch (e) {
        print('Error fetching members: $e');
        yield []; // Emit an empty list on error
      }

      await Future.delayed(const Duration(seconds: 5)); // Refresh every 10 seconds
    }
  }

  Stream<List<Map<String, dynamic>>> streamMembers(String supabaseUrl, String supabaseKey) async* {
    var apiUrl ='https://medicareplus-api.vercel.app';
    while (true) {
      try {
        final response = await http.get(
          Uri.parse('$apiUrl/api/admin/get_all_members'),
          headers: {
            'Content-Type': 'application/json',
            'supabase-url': supabaseUrl,
            'supabase-key': supabaseKey,
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          yield List<Map<String, dynamic>>.from(data['members'] ?? []);
        } else {
          throw Exception('Failed to load status count');
        }
      } catch (e) {
        print('Error: $e');
        yield []; // Emit an empty list on error
      }

      await Future.delayed(const Duration(seconds: 5)); // Refresh every 5 seconds
    }
  }

  /*Stream<List<Map<String, dynamic>>> streamMembers(String supabaseUrl, String supabaseKey) async* {
  var apiUrl = 'https://medicareplus-api.vercel.app/api/admin/get_all_members?page=1&pageSize=500'; // Initial URL
  List<Map<String, dynamic>> allMembers = [];  // Accumulate all members here

  while (apiUrl.isNotEmpty) {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'supabase-url': supabaseUrl,
          'supabase-key': supabaseKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Map<String, dynamic>> members = List<Map<String, dynamic>>.from(data['members'] ?? []);

        // Add the current page of members to the allMembers list
        allMembers.addAll(members);
        print('Fetched ${members.length} members, total: ${allMembers.length}');

        // Check if there is a nextPage URL in the pagination data
        String? nextPageUrl = data['pagination']?['nextPage'];

        // If there's a nextPage, update the apiUrl to the nextPage URL
        if (nextPageUrl != null && nextPageUrl.isNotEmpty) {
          // If nextPageUrl is relative, we need to prepend the base URL
          if (nextPageUrl.startsWith('/')) {
            apiUrl = 'https://medicareplus-api.vercel.app$nextPageUrl';
          } else {
            apiUrl = nextPageUrl;
          }
          print('Next page URL: $apiUrl');
        } else {
          // No more pages, exit the loop
          apiUrl = '';  
        }
      } else {
        throw Exception('Failed to load members, status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      yield []; // Emit an empty list on error
      break; // Exit the loop on error
    }

    // Wait for 5 seconds before fetching the next page to avoid rate limiting
    await Future.delayed(const Duration(seconds: 5));
  }

  // Once all pages are fetched, emit the full list of members
  yield allMembers;
}*/



Future<List<Map<String, dynamic>>> getMemberById(int customerId, String supabaseUrl, String supabaseKey) async {
  var myUrl = 'https://medicareplus-api.vercel.app';

  try {
    final response = await http.post(
      Uri.parse('$myUrl/api/admin/get_member_by_id?customer_id=$customerId'),
      headers: {
        'Content-Type': 'application/json',
        'supabase-url': supabaseUrl,
        'supabase-key': supabaseKey,
      },
      body: json.encode({
        'customer_id': customerId,  // Send customer_id in the request body
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      //print('Response data: $data');  // Debugging output

      // Check if 'members' is a list or a map
      if (data['members'] is List) {
        // If it's already a list, return it as a List<Map<String, dynamic>>
        return List<Map<String, dynamic>>.from(data['members']);
      } else if (data['members'] is Map) {
        // If it's a map (single member), convert it to a list with that single map
        return [data['members']];
      } else {
        // Return an empty list if 'members' is neither a List nor a Map
        return [];
      }
    } else {
      throw Exception('Failed to load member');
    }
  } catch (e) {
    print('Error: $e');
    return []; // Return an empty list on error
  }
}




}
