import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final email = TextEditingController(text: 'malazjanbeih@gmail.com');
  final password = TextEditingController();
  bool loading = false;
  List<Map<String, dynamic>> rows = [];
  Future<void> _login() async {
    if (email.text.trim().toLowerCase() != 'malazjanbeih@gmail.com') return;
    setState(() => loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
          email: email.text.trim(), password: password.text);
      await _load();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _load() async {
    final r = await Supabase.instance.client.rpc('admin_list_users');
    rows = List<Map<String, dynamic>>.from(r);
    if (mounted) setState(() {});
  }

  Future<void> _activateUser(String id) async {
    await Supabase.instance.client
        .rpc('activate_annual_subscription', params: {'target_user_id': id});
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        Supabase.instance.client.auth.currentUser?.email?.toLowerCase() ==
            'malazjanbeih@gmail.com';
    if (!isAdmin) {
      return Scaffold(
          appBar: AppBar(title: const Text('Admin')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: loading ? null : _login,
                  child: const Text('Sign in')),
            ]),
          ));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('SANA Admin')),
      body: ListView(
        children: rows
            .map((x) => Card(
                    child: ListTile(
                  title: Text('${x['name'] ?? ''}'),
                  subtitle: Text(
                      '${x['email'] ?? ''}\n${x['phone'] ?? ''}\nJoined: ${x['joining_date'] ?? ''}\nExpiry: ${x['expires_at'] ?? 'Not active'}'),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                      onPressed: () => _activateUser(x['id'].toString()),
                      child:
                          Text(x['status'] == 'active' ? 'Renew' : 'Activate')),
                )))
            .toList(),
      ),
    );
  }
}
