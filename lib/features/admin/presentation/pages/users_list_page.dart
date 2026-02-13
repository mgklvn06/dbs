// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dbs/config/routes.dart';
import 'package:dbs/core/widgets/app_background.dart';
import 'package:dbs/core/widgets/app_card.dart';

class UsersListPage extends StatelessWidget {
  const UsersListPage({super.key});

  Future<void> _setRole(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String role,
  ) async {
    final db = FirebaseFirestore.instance;
    final uid = doc.id;
    final now = FieldValue.serverTimestamp();
    final userRef = db.collection('users').doc(uid);
    final doctorRef = db.collection('doctors').doc(uid);
    final data = doc.data();

    try {
      await db.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);
        final userData = userSnap.data() ?? data;
        final name = (userData['displayName'] as String?) ?? 'Doctor';
        final email = userData['email'] as String?;
        final photoUrl = (userData['photoUrl'] as String?) ?? (userData['avatarUrl'] as String?);

        tx.update(userRef, {
          'role': role,
          'isAdmin': role == 'admin',
          'updatedAt': now,
        });

        if (role == 'doctor') {
          final doctorSnap = await tx.get(doctorRef);
          final doctorData = <String, dynamic>{
            'userId': uid,
            'name': name,
            'specialty': (doctorSnap.data()?['specialty'] as String?) ?? 'General',
            'bio': (doctorSnap.data()?['bio'] as String?) ?? '',
            'email': email,
            'photoUrl': photoUrl,
            'avatarUrl': photoUrl,
            'isActive': true,
            'updatedAt': now,
          };
          if (!doctorSnap.exists) doctorData['createdAt'] = now;
          tx.set(doctorRef, doctorData, SetOptions(merge: true));
        } else {
          final doctorSnap = await tx.get(doctorRef);
          if (doctorSnap.exists) {
            tx.update(doctorRef, {'isActive': false, 'updatedAt': now});
          }
        }
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role updated to $role')));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update role: $e')));
    }
  }

  Future<void> _setStatus(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String status,
  ) async {
    final db = FirebaseFirestore.instance;
    final uid = doc.id;
    final now = FieldValue.serverTimestamp();
    final userRef = db.collection('users').doc(uid);
    final doctorRef = db.collection('doctors').doc(uid);
    final role = (doc.data()['role'] as String?) ?? 'user';

    try {
      await db.runTransaction((tx) async {
        tx.update(userRef, {'status': status, 'updatedAt': now});
        if (role == 'doctor' && status == 'suspended') {
          final doctorSnap = await tx.get(doctorRef);
          if (doctorSnap.exists) {
            tx.update(doctorRef, {'isActive': false, 'updatedAt': now});
          }
        }
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status set to $status')));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  void _showActions(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String? selfUid,
  ) {
    final data = doc.data();
    final role = (data['role'] as String?) ?? 'user';
    final status = (data['status'] as String?) ?? 'active';
    final isSelf = doc.id == selfUid;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(data['displayName'] as String? ?? data['email'] as String? ?? doc.id),
                subtitle: Text('Role: $role  |  Status: $status'),
              ),
              const Divider(height: 1),
              ListTile(
                enabled: !isSelf && role != 'user',
                leading: const Icon(Icons.person_outline),
                title: const Text('Set role: user'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _setRole(context, doc, 'user');
                },
              ),
              ListTile(
                enabled: !isSelf && role != 'doctor',
                leading: const Icon(Icons.medical_services_outlined),
                title: const Text('Set role: doctor'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _setRole(context, doc, 'doctor');
                },
              ),
              ListTile(
                enabled: !isSelf && role != 'admin',
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Set role: admin'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _setRole(context, doc, 'admin');
                },
              ),
              const Divider(height: 1),
              ListTile(
                enabled: !isSelf && status != 'active',
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Set status: active'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _setStatus(context, doc, 'active');
                },
              ),
              ListTile(
                enabled: !isSelf && status != 'suspended',
                leading: const Icon(Icons.pause_circle_outline),
                title: const Text('Set status: suspended'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _setStatus(context, doc, 'suspended');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, Routes.login);
            },
          ),
        ],
      ),
      body: AppBackground(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load users'));
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No users found'));
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final name = (data['displayName'] as String?) ?? 'Unknown';
                final email = (data['email'] as String?) ?? 'no-email';
                final role = (data['role'] as String?) ?? 'unknown';
                final status = (data['status'] as String?) ?? 'active';
                final isSelf = doc.id == currentUser?.uid;
                return AppCard(
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$email - $role - $status${isSelf ? ' (you)' : ''}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showActions(context, doc, currentUser?.uid),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemCount: docs.length,
            );
          },
        ),
      ),
    );
  }
}
