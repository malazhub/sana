import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
//import 'package:intl/intl.dart';
import 'dart:convert';

// ============================================================================
// 1. STATE PROVIDER: ALL 5 SAVE/RESTORE LOGIC + USER ISOLATION
// ============================================================================

class SanaProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> medications = [];
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> pharmacies = [];
  List<Map<String, dynamic>> documents = [];
  List<Map<String, dynamic>> insurance = [];

  String? get userId => _client.auth.currentUser?.id;

  // Optimized Restore (startup)
  Future<void> restoreAllData() async {
    if (userId == null) return;
    final results = await Future.wait([
      _client.from('medications').select().eq('user_id', userId!),
      _client.from('doctors').select().eq('user_id', userId!),
      _client.from('pharmacies').select().eq('user_id', userId!),
      _client.from('documents').select().eq('user_id', userId!),
      _client.from('insurance').select().eq('user_id', userId!),
    ]);
    medications = List<Map<String, dynamic>>.from(results[0]);
    doctors = List<Map<String, dynamic>>.from(results[1]);
    pharmacies = List<Map<String, dynamic>>.from(results[2]);
    documents = List<Map<String, dynamic>>.from(results[3]);
    insurance = List<Map<String, dynamic>>.from(results[4]);
    notifyListeners();
  }

  // individual Save functions for all 5 categories
  Future<void> saveMed(
      String n, String d, String t, String b64, String r) async {
    await _client.from('medications').insert({
      'user_id': userId,
      'name': n,
      'dosage': d,
      'reminder_time': t,
      'photo_base64': b64,
      'ringtone_path': r
    });
    await restoreAllData();
  }

  Future<void> saveDoc(String n, String s, String p, String a) async {
    await _client.from('doctors').insert({
      'user_id': userId,
      'name': n,
      'specialty': s,
      'phone': p,
      'address': a
    });
    await restoreAllData();
  }

  Future<void> savePharm(String n, String a, String p) async {
    await _client.from('pharmacies').insert({
      'user_id': userId,
      'name': n,
      'address': a,
      'phone': p
    });
    await restoreAllData();
  }

  Future<void> saveDocument(String t, String c, String url) async {
    await _client.from('documents').insert({
      'user_id': userId,
      'title': t,
      'category': c,
      'file_url': url
    });
    await restoreAllData();
  }

  Future<void> saveInsurance(String n, String p, String e) async {
    await _client.from('insurance').insert({
      'user_id': userId,
      'provider_name': n,
      'policy_number': p,
      'expiry': e
    });
    await restoreAllData();
  }

  void clearLocal() {
    medications.clear();
    doctors.clear();
    pharmacies.clear();
    documents.clear();
    insurance.clear();
    notifyListeners();
  }

  String generateFullReport() {
    return """SANA SMART HEALTH COMPLETE MEDICAL RECORD
--- MEDICATIONS ---
${medications.map((m) => "${m['name']} (${m['dosage']}) at ${m['reminder_time']}").join('\n')}
--- DOCTORS ---
${doctors.map((d) => "Dr. ${d['name']} (${d['specialty']}) - ${d['phone']}").join('\n')}
--- PHARMACIES ---
${pharmacies.map((p) => "${p['name']} at ${p['address']}").join('\n')}
--- INSURANCE ---
${insurance.map((i) => i['provider_name']).join('\n')}
--- DOCUMENTS ---
Total files stored: ${documents.length}""";
  }
}

// ============================================================================
// 2. MAIN APP & HOME SCREEN: LOGO + SANA + 20-DAY BANNER
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_URL',
    publishableKey:
        'sb_publishable_3f7AQFQw-Kx0_Qvir4nFXQ_XZmUMpzm',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SanaProvider(),
        ),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      ),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final client = Supabase.instance.client;
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    _securityWorkflow();
  }

  Future<void> _securityWorkflow() async {
    final user = client.auth.currentUser;
    if (user == null) return;

    await client.rpc('process_account_expiry');

    final data = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted) return;

    setState(() => profile = data);

    if (profile != null && profile!['is_active'] == true) {
      context.read<SanaProvider>().restoreAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SanaProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // LOGO + SANA + SHARING
                const SizedBox(height: 15),

                const Center(
                  child: Icon(
                    Icons.health_and_safety,
                    size: 70,
                    color: Colors.teal,
                  ),
                ),

                const Center(
                  child: Text(
                    "SANA",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.share,
                    color: Colors.orange,
                    size: 30,
                  ),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: state.generateFullReport(),
                    ),
                  ),
                ),

                const Divider(
                  indent: 50,
                  endIndent: 50,
                ),

                // 20-DAY BANNER
                if (profile != null) _buildExpiryBanner(profile!),

                // RESPONSIVE FEATURE GRID
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(12),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.45,
                    children: [
                      _card(
                        "Medications",
                        Icons.medication,
                        Colors.blue,
                        () => _showMedPhoto(context),
                      ),
                      _card(
                        "Doctors",
                        Icons.person,
                        Colors.green,
                        () => state.restoreAllData(),
                      ),
                      _card(
                        "Pharmacies",
                        Icons.local_pharmacy,
                        Colors.orange,
                        () => state.restoreAllData(),
                      ),
                      _card(
                        "Documents",
                        Icons.folder,
                        Colors.purple,
                        () => state.restoreAllData(),
                      ),
                      _card(
                        "Insurance",
                        Icons.credit_card,
                        Colors.indigo,
                        () => state.restoreAllData(),
                      ),
                      _card(
                        "Full Share",
                        Icons.history,
                        Colors.teal,
                        () => SharePlus.instance.share(
                          ShareParams(
                            text: state.generateFullReport(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildFooter(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpiryBanner(Map<String, dynamic> p) {
    if (p['expiry_date'] == null) {
      return const SizedBox.shrink();
    }

    final expiry = DateTime.parse(p['expiry_date']);
    final days = expiry.difference(DateTime.now()).inDays;

    if (days < 0 || !p['is_active']) {
      return const Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          "ACCOUNT EXPIRED - CONTACT ADMIN",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (days > 20) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.red,
      padding: const EdgeInsets.all(10),
      child: Text(
        "⚠️ Account expires in $days days!",
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showMedPhoto(BuildContext context) {
    final meds = context.read<SanaProvider>().medications;

    if (meds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(meds[0]['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (meds[0]['photo_base64'] != null)
              Image.memory(
                base64Decode(meds[0]['photo_base64']!),
                height: 100,
              ),
            Text(
              "Dose: ${meds[0]['dosage']}\nReminder: ${meds[0]['reminder_time']}\nRingtone: ${meds[0]['ringtone_path']}",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  Widget _card(
    String t,
    IconData i,
    Color c,
    VoidCallback a,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: a,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              i,
              color: c,
              size: 30,
            ),
            Text(
              t,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => _adminAuth(context),
              child: const Text(
                "ADMIN KEY",
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (auth.currentUser == null)
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                child: const Text(
                  "LOGIN",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (auth.currentUser != null)
            Expanded(
              child: TextButton(
                onPressed: () async {
                  await auth.signOut();
                  context.read<SanaProvider>().clearLocal();
                  setState(() => profile = null);
                },
                child: const Text(
                  "LOGOUT",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _adminAuth(BuildContext context) {
    if (profile?['email'] == 'malazjanbaih@gmail.com') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }
}

// ============================================================================
// 3. ADMIN SCREEN: USERS TABLE + ALERTS TAB
// ============================================================================

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("SANA Admin Panel"),
          backgroundColor: Colors.teal,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Users"),
              Tab(text: "Alerts"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUsersTab(client),
            _buildAlertsTab(client),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(SupabaseClient client) {
    return StreamBuilder(
      stream: client
          .from('profiles')
          .stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Email")),
              DataColumn(label: Text("Phone")),
              DataColumn(label: Text("Joined")),
              DataColumn(label: Text("Expiry")),
              DataColumn(label: Text("Action")),
            ],
            rows: snapshot.data!
                .map(
                  (u) => DataRow(
                    cells: [
                      DataCell(
                        Text(u['name'] ?? 'Guest'),
                      ),
                      DataCell(
                        Text(u['email']),
                      ),
                      DataCell(
                        Text(u['phone'] ?? 'N/A'),
                      ),
                      DataCell(
                        Text(
                          u['joining_date']
                                  ?.toString()
                                  .split('T')
                                  .first ??
                              'N/A',
                        ),
                      ),
                      DataCell(
                        Text(
                          u['expiry_date']
                                  ?.toString()
                                  .split('T')
                                  .first ??
                              'N/A',
                        ),
                      ),
                      DataCell(
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                u['is_active']
                                    ? Colors.red
                                    : Colors.green,
                          ),
                          onPressed: () async {
                            await client.rpc(
                              'admin_set_user_active',
                              params: {
                                'target_user': u['id'],
                                'activate': !u['is_active'],
                              },
                            );
                          },
                          child: Text(
                            u['is_active']
                                ? "Deactivate"
                                : "Activate",
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab(SupabaseClient client) {
    return StreamBuilder(
      stream: client
          .from('system_alerts')
          .stream(primaryKey: ['id'])
          .order('created_at'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return ListView(
          children: snapshot.data!
              .map(
                (a) => ListTile(
                  leading: const Icon(
                    Icons.warning,
                    color: Colors.red,
                  ),
                  title: Text(a['type']),
                  subtitle: Text(a['message']),
                  trailing: Text(
                    a['created_at']
                        .toString()
                        .split('T')
                        .first,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

// ============================================================================
// 4. LOGIN SCREEN (SECURE AUTH)
// ============================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),
            TextField(
              controller: pass,
              decoration: const InputDecoration(
                labelText: "Password",
              ),
              obscureText: true,
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () async {
                await Supabase.instance.client.auth
                    .signInWithPassword(
                  email: email.text,
                  password: pass.text,
                );

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                  (r) => false,
                );
              },
              child: const Text("SIGN IN"),
            ),
          ],
        ),
      ),
    );
  }
}