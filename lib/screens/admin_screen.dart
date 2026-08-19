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
  static const String _adminEmail = 'malazjanbeih@gmail.com';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;

      if (user?.email?.trim().toLowerCase() == _adminEmail) {
        context.read<AdminProvider>().loadUsers();
      }
    });
  }

  bool _isAdmin() {
    final email = Supabase
        .instance
        .client
        .auth
        .currentUser
        ?.email
        ?.trim()
        .toLowerCase();

    return email == _adminEmail;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin()) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Admin access is restricted to authorized personnel.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SANA Admin Panel'),
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: adminProvider.isLoading
                    ? null
                    : adminProvider.loadUsers,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _buildBody(
            context,
            adminProvider,
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminProvider adminProvider,
  ) {
    if (adminProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (adminProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                adminProvider.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: adminProvider.loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (adminProvider.users.isEmpty) {
      return RefreshIndicator(
        onRefresh: adminProvider.loadUsers,
        child: ListView(
          children: const [
            SizedBox(height: 200),
            Center(
              child: Text(
                'No users found.',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: adminProvider.loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: adminProvider.users.length,
        itemBuilder: (context, index) {
          final user = adminProvider.users[index];

          return _UserCard(
            user: user,
            adminProvider: adminProvider,
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.adminProvider,
  });

  final Map<String, dynamic> user;
  final AdminProvider adminProvider;

  String _stringValue(
    String key, {
    String fallback = 'N/A',
  }) {
    final value = user[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  bool get isActive {
    return user['status']?.toString().toLowerCase() == 'active';
  }

  bool get isExpired {
    return adminProvider.isExpired(user);
  }

  bool get expiresSoon {
    return adminProvider.expiresWithin20Days(user);
  }

  Color get statusColor {
    if (isExpired) {
      return Colors.red;
    }

    if (expiresSoon) {
      return Colors.orange;
    }

    if (isActive) {
      return Colors.green;
    }

    return Colors.grey;
  }

  String get statusText {
    if (isExpired) {
      return 'Expired';
    }

    if (expiresSoon) {
      return 'Expires Soon';
    }

    if (isActive) {
      return 'Active';
    }

    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final email = _stringValue('user_email');
    final phone = _stringValue('user_phone');
    final userId = _stringValue('user_id', fallback: '');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: const Icon(
            Icons.person,
            color: Colors.teal,
          ),
        ),
        title: Text(
          email,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Phone: $phone',
          ),
        ),
        trailing: _StatusBadge(
          text: statusText,
          color: statusColor,
        ),
        onTap: () {
          _showUserDetails(
            context,
            userId,
            email,
            phone,
          );
        },
      ),
    );
  }

  Future<void> _showUserDetails(
    BuildContext context,
    String userId,
    String email,
    String phone,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('User Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  label: 'Email',
                  value: email,
                ),
                _DetailRow(
                  label: 'Phone',
                  value: phone,
                ),
                _DetailRow(
                  label: 'Status',
                  value: _stringValue('status'),
                ),
                _DetailRow(
                  label: 'Activated',
                  value: _stringValue(
                    'activated_at',
                    fallback: 'Not activated',
                  ),
                ),
                _DetailRow(
                  label: 'Expires',
                  value: _stringValue('expires_at'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Close'),
            ),
            if (!isActive || isExpired)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text('Activate 1 Year'),
                onPressed: userId.isEmpty
                    ? null
                    : () async {
                        Navigator.of(dialogContext).pop(true);

                        final success =
                            await adminProvider.activateUser(
                          userId,
                          email,
                          phone,
                        );

                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'User activated for one year.'
                                  : adminProvider.errorMessage ??
                                      'Unable to activate user.',
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                          ),
                        );
                      },
              ),
            if (isActive && !isExpired)
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: userId.isEmpty
                    ? null
                    : () async {
                        final confirmed =
                            await _confirmDeactivation(
                          context,
                          email,
                        );

                        if (!confirmed || !context.mounted) {
                          return;
                        }

                        Navigator.of(dialogContext).pop(true);

                        final success =
                            await adminProvider.deactivateUser(
                          userId,
                        );

                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'User deactivated.'
                                  : adminProvider.errorMessage ??
                                      'Unable to deactivate user.',
                            ),
                            backgroundColor:
                                success ? Colors.orange : Colors.red,
                          ),
                        );
                      },
                child: const Text('Deactivate'),
              ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      await adminProvider.loadUsers();
    }
  }

  Future<bool> _confirmDeactivation(
    BuildContext context,
    String email,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Deactivate User?'),
          content: Text(
            'Are you sure you want to deactivate $email?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}