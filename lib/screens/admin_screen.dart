import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/admin_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (mounted &&
          user != null &&
          user.email?.toLowerCase() == 'malazjanbeih@gmail.com') {
        context.read<AdminProvider>().loadUsers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // STRICT ADMIN GATEKEEPER
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.email?.toLowerCase() != 'malazjanbeih@gmail.com') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Admin access is strictly restricted to authorized personnel.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, foregroundColor: Colors.white),
              icon: const Icon(Icons.refresh),
              label: const Text('Reload Users'),
              onPressed: () => adminProvider.loadUsers(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: adminProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : adminProvider.users.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.builder(
                          itemCount: adminProvider.users.length,
                          itemBuilder: (ctx, i) {
                            final userRow = adminProvider.users[i];
                            final isActive = userRow['status'] == 'active';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.person,
                                    color: Colors.teal),
                                title:
                                    Text(userRow['user_email'] ?? 'No Email'),
                                subtitle: Text(
                                    'Phone: ${userRow['user_phone'] ?? 'N/A'}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        isActive ? Colors.green : Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Pending',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (dialogCtx) => AlertDialog(
                                      title: const Text('User Details'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Email: ${userRow['user_email'] ?? 'N/A'}'),
                                          const SizedBox(height: 4),
                                          Text(
                                              'Phone: ${userRow['user_phone'] ?? 'N/A'}'),
                                          const SizedBox(height: 4),
                                          Text(
                                              'Status: ${userRow['status'] ?? 'pending'}'),
                                          const SizedBox(height: 4),
                                          Text(
                                              'Activated: ${userRow['activated_at'] ?? 'Not activated'}'),
                                          const SizedBox(height: 4),
                                          Text(
                                              'Expires: ${userRow['expires_at'] ?? 'N/A'}'),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dialogCtx),
                                          child: const Text('Close'),
                                        ),
                                        if (!isActive)
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white),
                                            onPressed: () async {
                                              Navigator.pop(dialogCtx);

                                              // FIXED: Avoids void result error by not assigning to a variable
                                              await adminProvider.activateUser(
                                                userRow['user_id'] ?? '',
                                                userRow['user_email'] ?? '',
                                                userRow['user_phone'] ?? '',
                                              );

                                              if (context.mounted) {
                                                adminProvider.loadUsers();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'User activated successfully!'),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            },
                                            child:
                                                const Text('Activate 1 Year'),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
