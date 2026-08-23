import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({
    super.key,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  bool _actionInProgress = false;

  static const Color _primary = Color(0xFF009688);
  static const Color _darkPrimary = Color(0xFF008F83);
  static const Color _background = Color(0xFFF4FAF9);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<AdminProvider>().loadUsers();
    });
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> _signOut() async {
    if (_actionInProgress) return;

    setState(() {
      _actionInProgress = true;
    });

    try {
      await context.read<AuthProvider>().signOut();
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        title: 'Sign Out Failed',
        message: _cleanError(error),
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionInProgress = false;
        });
      }
    }
  }

  // ============================================================
  // BACK
  // ============================================================

  void _goBack() {
    Navigator.of(context).maybePop();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage({
    required String title,
    required String message,
    required IconData icon,
  }) {
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              8,
              24,
              32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 52,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated || !auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Administrator'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 72,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Administrator access required.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _goBack,
                  child: const Text('Return'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings),
            SizedBox(width: 10),
            Text(
              'Admin Panel',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _actionInProgress
                ? null
                : () {
                    context
                        .read<AdminProvider>()
                        .loadUsers();
                  },
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _actionInProgress ? null : _signOut,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          _buildUsersPage(),
          _buildStatisticsPage(),
          _buildSecurityPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });

          if (index == 1) {
            context.read<AdminProvider>().loadUsers();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security),
            label: 'Security',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget _buildDashboard() {
    final admin = context.watch<AdminProvider>();
    final users = admin.users;

    final totalUsers = users.length;

    final activeUsers = users.where(admin.isActive).length;

    final pendingUsers = users
        .where(
          (user) =>
              !admin.isActive(user) &&
              !admin.isExpired(user),
        )
        .length;

    final expiredUsers = users.where(admin.isExpired).length;

    return RefreshIndicator(
      onRefresh: () {
        return context.read<AdminProvider>().loadUsers();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(
              icon: Icons.dashboard,
              title: 'Administrator Dashboard',
              subtitle:
                  'Control payment activations and review subscriptions.',
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              children: [
                _buildStatCard(
                  icon: Icons.people,
                  title: 'Total Users',
                  value: '$totalUsers',
                ),
                _buildStatCard(
                  icon: Icons.check_circle_outline,
                  title: 'Active',
                  value: '$activeUsers',
                ),
                _buildStatCard(
                  icon: Icons.hourglass_top_outlined,
                  title: 'Pending',
                  value: '$pendingUsers',
                ),
                _buildStatCard(
                  icon: Icons.cancel_outlined,
                  title: 'Expired',
                  value: '$expiredUsers',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'Subscription Flow',
              text:
                  'New users remain pending until payment is confirmed. '
                  'The protected backend RPC records the payment and '
                  'calculates the one-year subscription period.',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // USERS
  // ============================================================

  Widget _buildUsersPage() {
    final admin = context.watch<AdminProvider>();
    final users = admin.users;

    if (admin.isLoading && users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: _primary,
        ),
      );
    }

    if (admin.errorMessage != null && users.isEmpty) {
      return RefreshIndicator(
        onRefresh: () {
          return context.read<AdminProvider>().loadUsers();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            const Icon(
              Icons.error_outline,
              size: 56,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: Text(
                admin.errorMessage!,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: FilledButton.icon(
                onPressed: () {
                  context.read<AdminProvider>().loadUsers();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        return context.read<AdminProvider>().loadUsers();
      },
      child: users.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'No registered customers found.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _buildUserCard(users[index]);
              },
            ),
    );
  }

  // ============================================================
  // USER CARD
  // ============================================================

  Widget _buildUserCard(
    Map<String, dynamic> user,
  ) {
    final admin = context.watch<AdminProvider>();

    final active = admin.isActive(user);
    final status = admin.statusText(user);

    final name = _valueOrDefault(
      user['user_name'],
      'Unnamed',
    );

    final email = _valueOrDefault(
      user['user_email'],
      'No email',
    );

    final phone = user['user_phone']?.toString().trim() ?? '';

    final userId = user['user_id']?.toString().trim() ?? '';

    final remaining = admin.daysRemaining(user);

    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    name.isNotEmpty
                        ? name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (active && remaining != null) ...[
              const SizedBox(height: 12),
              Text(
                remaining == 1
                    ? 'Remaining: 1 day'
                    : 'Remaining: $remaining days',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: _buildUserAction(
                userId: userId,
                userName: name,
                active: active,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // USER ACTION
  // ============================================================

  Widget _buildUserAction({
    required String userId,
    required String userName,
    required bool active,
  }) {
    if (userId.isEmpty) {
      return const Text(
        'Invalid user record',
        style: TextStyle(
          color: Colors.red,
          fontSize: 13,
        ),
      );
    }

    if (active) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.green.withValues(
            alpha: 0.10,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              color: Colors.green,
              size: 18,
            ),
            SizedBox(width: 7),
            Text(
              'Subscription Active',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
      ),
      icon: const Icon(
        Icons.check,
        size: 18,
      ),
      label: const Text(
        'Confirm Payment & Activate',
      ),
      onPressed: _actionInProgress
          ? null
          : () {
              _openActivationDialog(
                userId,
                userName,
              );
            },
    );
  }

  // ============================================================
  // ACTIVATION DIALOG
  // ============================================================

  Future<void> _openActivationDialog(
    String userId,
    String userName,
  ) async {
    final transactionCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '50.0');
    final currencyCtrl = TextEditingController(text: 'USD');
    final notesCtrl = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool submitting = false;

          return StatefulBuilder(
            builder: (
              context,
              setDialogState,
            ) {
              return AlertDialog(
                title: Text(
                  'Activate: $userName',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Enter the payment information. '
                        'The server will create the subscription and '
                        'calculate its one-year expiry date.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: transactionCtrl,
                        enabled: !submitting,
                        decoration: const InputDecoration(
                          labelText: 'Transaction ID *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: amountCtrl,
                              enabled: !submitting,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Amount *',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: currencyCtrl,
                              enabled: !submitting,
                              textCapitalization:
                                  TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Currency',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        enabled: !submitting,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: submitting
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                    ),
                    onPressed: submitting
                        ? null
                        : () async {
                            final transactionId =
                                transactionCtrl.text.trim();

                            final amount = double.tryParse(
                                  amountCtrl.text.trim(),
                                ) ??
                                0;

                            final currency =
                                currencyCtrl.text.trim();

                            final notes =
                                notesCtrl.text.trim();

                            if (transactionId.isEmpty) {
                              _showDialogError(
                                context,
                                'Transaction ID is required.',
                              );
                              return;
                            }

                            if (amount <= 0) {
                              _showDialogError(
                                context,
                                'Amount must be greater than zero.',
                              );
                              return;
                            }

                            if (currency.length != 3) {
                              _showDialogError(
                                context,
                                'Currency must be a 3-letter code such as USD.',
                              );
                              return;
                            }

                            setDialogState(() {
                              submitting = true;
                            });

                            if (mounted) {
                              setState(() {
                                _actionInProgress = true;
                              });
                            }

                            final success = await context
                                .read<AdminProvider>()
                                .confirmPayment(
                                  userId: userId,
                                  transactionId: transactionId,
                                  amount: amount,
                                  currency: currency,
                                  paidAt: DateTime.now(),
                                  notes: notes.isNotEmpty
                                      ? notes
                                      : null,
                                );

                            if (!mounted) return;

                            setState(() {
                              _actionInProgress = false;
                            });

                            final error = context
                                .read<AdminProvider>()
                                .errorMessage;

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            if (!mounted) return;

                            _showMessage(
                              title: success
                                  ? 'User Activated'
                                  : 'Activation Failed',
                              message: success
                                  ? 'Payment confirmed and $userName now has an active one-year subscription.'
                                  : error ??
                                      'Failed to activate user.',
                              icon: success
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                            );
                          },
                    child: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirm & Activate',
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      transactionCtrl.dispose();
      amountCtrl.dispose();
      currencyCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  // ============================================================
  // DIALOG VALIDATION ERROR
  // ============================================================

  void _showDialogError(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatisticsPage() {
    final admin = context.watch<AdminProvider>();
    final users = admin.users;

    final activeCount =
        users.where(admin.isActive).length;

    final pendingCount = users
        .where(
          (user) =>
              !admin.isActive(user) &&
              !admin.isExpired(user),
        )
        .length;

    final expiredCount =
        users.where(admin.isExpired).length;

    final expiringCount =
        users.where(admin.expiresWithin20Days).length;

    return RefreshIndicator(
      onRefresh: () {
        return context.read<AdminProvider>().loadUsers();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(
              icon: Icons.bar_chart,
              title: 'Statistics & Analytics',
              subtitle:
                  'Overview of subscriptions and customer status.',
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              icon: Icons.pie_chart,
              title: 'User Distribution',
              text:
                  'Registered Customers: ${users.length}\n'
                  'Active Subscriptions: $activeCount\n'
                  'Pending Customers: $pendingCount\n'
                  'Expired Subscriptions: $expiredCount\n'
                  'Expiring in ≤20 Days: $expiringCount',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECURITY
  // ============================================================

  Widget _buildSecurityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.security,
            title: 'Security Architecture',
            subtitle:
                'Role-based access control and protected backend operations.',
          ),
          const SizedBox(height: 20),
          _buildSecurityTile(
            icon: Icons.admin_panel_settings,
            title: 'Role Validation',
            subtitle:
                'Administrator access is determined from the authenticated user profile and must be enforced server-side.',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildSecurityTile(
            icon: Icons.payment,
            title: 'Payment Confirmation',
            subtitle:
                'Administrators confirm customer payments through the protected admin_confirm_payment RPC.',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildSecurityTile(
            icon: Icons.key,
            title: 'One-Year Activation',
            subtitle:
                'The backend calculates the activation and expiry dates. Flutter never chooses the subscription expiry date.',
            color: Colors.deepOrange,
          ),
          const SizedBox(height: 12),
          _buildSecurityTile(
            icon: Icons.storage,
            title: 'Non-Destructive Data',
            subtitle:
                'The admin UI does not directly delete or manipulate subscription records.',
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildSecurityTile(
            icon: Icons.logout,
            title: 'Session Control',
            subtitle:
                'Signing out terminates the current Supabase authentication session.',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _darkPrimary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(
              alpha: 0.18,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFD5F5F1),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _darkPrimary,
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _darkPrimary,
            size: 30,
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECURITY TILE
  // ============================================================

  Widget _buildSecurityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withValues(
              alpha: 0.12,
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _valueOrDefault(
    dynamic value,
    String fallback,
  ) {
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _cleanError(
    Object error,
  ) {
    final text = error.toString().trim();

    if (text.startsWith('Exception: ')) {
      return text.substring(
        'Exception: '.length,
      );
    }

    return text.isEmpty
        ? 'An unexpected error occurred.'
        : text;
  }
}