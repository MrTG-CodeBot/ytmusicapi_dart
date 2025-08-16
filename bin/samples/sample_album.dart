import 'package:dart_ytmusicapi/dart_ytmusicapi.dart';
import 'dart:convert';

void main() async {
  final ytm = YTMusic();

  try {
    print('Searching for "slay!" songs...');
    final results = await ytm.search(query: 'rdx', filter: 'albums');


    if (results.isEmpty) {
      print('No songs found.');
    } else {
      print('Found albums:');
      print("${JsonEncoder.withIndent('  ').convert(results)}");
    }
  } catch (e) {
    print('An error occurred: $e');
  }
}