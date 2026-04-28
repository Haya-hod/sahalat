
import 'package:flutter/material.dart';

class MatchesScreen extends StatelessWidget {
static const route = '/matches';
const MatchesScreen({super.key});

@override
Widget build(BuildContext context) {
final all = List.generate(12, (i) => {
'title': 'Match #${i+1}',
'date': 'Nov ${12 + (i % 7)}, ${(18 + i) % 24}:00',
'venue': 'Stadium ${(i % 4) + 1}',
});

return Scaffold(
  backgroundColor: const Color(0xFFF4F6FA),
appBar: AppBar(title: const Text('Matches')),
body: ListView.separated(
padding: const EdgeInsets.all(16),
itemCount: all.length,
separatorBuilder: (_, __) => const SizedBox(height: 10),
itemBuilder: (_, i) {
final m = all[i];
return Card(
child: ListTile(
leading: const Icon(Icons.sports_soccer),
title: Text(m['title']!),
subtitle: Text('${m['date']} • ${m['venue']}'),
onTap: () {}, // تفاصيل المباراة لاحقًا
),
);
},
),
);
}
}
