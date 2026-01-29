import 'package:flutter/material.dart';

class UsersListPage extends StatelessWidget {
  const UsersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder users list
    final users = List.generate(8, (i) => 'User ${i + 1}');

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(users[index]),
          subtitle: const Text('patient@example.com'),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ),
        separatorBuilder: (_, __) => const Divider(),
        itemCount: users.length,
      ),
    );
  }
}
