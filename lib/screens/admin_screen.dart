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
  static const Color _primary = Color(0xFF009688);
  static const Color _darkPrimary = Color(0xFF008F83);
  static const Color _background = Color(0xFFF4FAF9);

  int _selectedIndex = 0;
  bool _actionInProgress = false;

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
      final auth = context.read<AuthProvider>();

      await auth.signOut();

      if (!mounted) return;

      final error = auth.errorMessage;

      if (error != null && error.trim().isNotEmpty) {
        _showMessage(
          title: 'Sign Out Failed',
          message: error,
          icon: Icons.error_outline,
        );
      }
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
          onPressed:
              _actionInProgress ? null : _goBack,
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
                : _refreshUsers,
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed:
                _actionInProgress ? null : _signOut,
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
          if (_actionInProgress) return;

          setState(() {
            _selectedIndex = index;
          });

          if (index == 1) {
            _refreshUsers();
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
  // REFRESH
  // ============================================================

  Future<void> _refreshUsers() async {
    if (!mounted) return;

    await context.read<AdminProvider>().loadUsers();
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget _buildDashboard() {
    final admin = context.watch<AdminProvider>();
    final users = admin.users;

    final totalUsers = users.length;

    final activeUsers =
        users.where(admin.isActive).length;

    final pendingUsers = users
        .where(
          (user) =>
              !admin.isActive(user) &&
              !admin.isExpired(user),
        )
        .length;

    final expiredUsers =
        users.where(admin.isExpired).length;

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
              physics:
                  const NeverScrollableScrollPhysics(),
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

    if (admin.errorMessage != null &&
        users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshUsers,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            const Icon(
              Icons.error_outline,
              size: 56,
            ),
            const SizedBox(height: 16),
            Padding(
              padding:
                  const EdgeInsets.symmetric(
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
                onPressed: _refreshUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshUsers,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),
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

    final phone =
        user['user_phone']?.toString().trim() ?? '';

    final userId =
        user['user_id']?.toString().trim() ?? '';

    final remaining =
        admin.daysRemaining(user);

    final statusColor =
        _statusColor(status);

    return Card(
      margin:
          const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      _primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    name.isNotEmpty
                        ? name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: _primary,
                      fontWeight:
                          FontWeight.bold,
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
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          phone,
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        statusColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight:
                          FontWeight.bold,
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
              alignment:
                  Alignment.centerRight,
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
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              Colors.red.shade700,
          side: BorderSide(
            color: Colors.red.shade200,
          ),
        ),
        icon: const Icon(
          Icons.block,
          size: 18,
        ),
        label: const Text('Deactivate'),
        onPressed: _actionInProgress
            ? null
            : () => _confirmDeactivation(
                  userId,
                  userName,
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
          : () => _openActivationDialog(
                userId,
                userName,
              ),
    );
  }

  // ============================================================
  // ACTIVATION
  // ============================================================

  Future<void> _openActivationDialog(
    String userId,
    String userName,
  ) async {
    final transactionController =
        TextEditingController();

    final amountController =
        TextEditingController(
      text: '50.0',
    );

    final currencyController =
        TextEditingController(
      text: 'USD',
    );

    final notesController =
        TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool submitting = false;

          return StatefulBuilder(
            builder: (
              dialogBuildContext,
              setDialogState,
            ) {
              return AlertDialog(
                title: Text(
                  'Activate: $userName',
                ),
                content:
                    SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Text(
                        'Record the payment details. '
                        'The protected backend RPC calculates '
                        'the subscription expiry.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller:
                            transactionController,
                        enabled: !submitting,
                        textInputAction:
                            TextInputAction.next,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Transaction ID *',
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller:
                                  amountController,
                              enabled:
                                  !submitting,
                              keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                decimal: true,
                              ),
                              textInputAction:
                                  TextInputAction.next,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Amount *',
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller:
                                  currencyController,
                              enabled:
                                  !submitting,
                              textCapitalization:
                                  TextCapitalization
                                      .characters,
                              textInputAction:
                                  TextInputAction.next,
                              decoration:
                                  const InputDecoration(
                                labelText:
                                    'Currency',
                                border:
                                    OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller:
                            notesController,
                        enabled: !submitting,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Notes (Optional)',
                          border:
                              OutlineInputBorder(),
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
                            Navigator.of(
                              dialogContext,
                            ).pop();
                          },
                    child:
                        const Text('Cancel'),
                  ),
                  FilledButton(
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          _primary,
                    ),
                    onPressed: submitting
                        ? null
                        : () async {
                            final transactionId =
                                transactionController
                                    .text
                                    .trim();

                            final amount =
                                double.tryParse(
                                      amountController
                                          .text
                                          .trim(),
                                    ) ??
                                    0;

                            final currency =
                                currencyController
                                    .text
                                    .trim();

                            final notes =
                                notesController
                                    .text
                                    .trim();

                            if (transactionId
                                    .length <
                                3) {
                              _showDialogError(
                                dialogBuildContext,
                                'Please enter a valid transaction ID.',
                              );
                              return;
                            }

                            if (amount <= 0) {
                              _showDialogError(
                                dialogBuildContext,
                                'Please enter a payment amount greater than zero.',
                              );
                              return;
                            }

                            if (currency.isEmpty) {
                              _showDialogError(
                                dialogBuildContext,
                                'Please enter a currency.',
                              );
                              return;
                            }

                            setDialogState(() {
                              submitting = true;
                            });

                            if (mounted) {
                              setState(() {
                                _actionInProgress =
                                    true;
                              });
                            }

                            final success =
                                await context
                                    .read<
                                        AdminProvider>()
                                    .activateUser(
                                      userId,
                                      transactionId:
                                          transactionId,
                                      amount: amount,
                                      currency:
                                          currency,
                                      paidAt:
                                          DateTime.now()
                                              .toUtc(),
                                      notes:
                                          notes.isEmpty
                                              ? null
                                              : notes,
                                    );

                            if (!mounted) {
                              return;
                            }

                            setState(() {
                              _actionInProgress =
                                  false;
                            });

                            if (dialogContext
                                .mounted) {
                              Navigator.of(
                                dialogContext,
                              ).pop();
                            }

                            if (!mounted) {
                              return;
                            }

                            final admin =
                                context.read<
                                    AdminProvider>();

                            _showMessage(
                              title: success
                                  ? 'User Activated'
                                  : 'Activation Failed',
                              message: success
                                  ? 'Subscription for $userName is now active for 1 year.'
                                  : admin.errorMessage ??
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
                            child:
                                CircularProgressIndicator(
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
      transactionController.dispose();
      amountController.dispose();
      currencyController.dispose();
      notesController.dispose();
    }
  }

  // ============================================================
  // DEACTIVATION
  // ============================================================

  Future<void> _confirmDeactivation(
    String userId,
    String userName,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              Text('Deactivate $userName?'),
          content: const Text(
            'This will deactivate the customer subscription '
            'without deleting customer or application data.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child:
                  const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true ||
        !mounted ||
        _actionInProgress) {
      return;
    }

    setState(() {
      _actionInProgress = true;
    });

    final success =
        await context
            .read<AdminProvider>()
            .deactivateUser(userId);

    if (!mounted) return;

    setState(() {
      _actionInProgress = false;
    });

    final admin =
        context.read<AdminProvider>();

    _showMessage(
      title: success
          ? 'Deactivated'
          : 'Deactivation Failed',
      message: success
          ? 'User $userName has been marked as inactive.'
          : admin.errorMessage ??
              'Failed to deactivate user.',
      icon: success
          ? Icons.check_circle
          : Icons.error_outline,
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

    final expiringCount = users
        .where(
          admin.expiresWithin20Days,
        )
        .length;

    return RefreshIndicator(
      onRefresh: _refreshUsers,
      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildPageHeader(
              icon: Icons.bar_chart,
              title: 'Statistics & Analytics',
              subtitle:
                  'Overview of platform usage and subscription status.',
            ),
            const SizedBox(height: 20),
            _buildInfoCard(
              icon: Icons.pie_chart,
              title: 'User Distribution',
              text:
                  'Registered Customers: ${users.length}\n'
                  'Active Subscriptions: $activeCount\n'
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            icon: Icons.security,
            title: 'Security Architecture',
            subtitle:
                'Role-based access control and protected RPC operations.',
          ),
          const SizedBox(height: 20),
          _buildSecurityTile(
            icon:
                Icons.admin_panel_settings,
            title: 'Role Validation',
            subtitle:
                'Access is granted only when the server-side users.role value is admin.',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildSecurityTile(
            icon: Icons.payment,
            title: 'Payment Confirmation',
            subtitle:
                'Administrators confirm customer payments from the User Management screen.',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildSecurityTile(
            icon: Icons.key,
            title: 'One-Year Activation',
            subtitle:
                'The protected server-side RPC calculates the subscription expiry. Flutter never chooses the expiry date.',
            color: Colors.deepOrange,
          ),
          const SizedBox(height: 12),
          _buildSecurityTile(
            icon: Icons.delete_outline,
            title: 'Non-Destructive Deactivation',
            subtitle:
                'Deactivating an account changes access state only. Customer/application data is not deleted.',
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildSecurityTile(
            icon: Icons.logout,
            title: 'Session Control',
            subtitle:
                'Sign Out terminates the current administrator Supabase session.',
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
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                Colors.white.withValues(
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
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color:
                        Color(0xFFD5F5F1),
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
        borderRadius:
            BorderRadius.circular(18),
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
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  text,
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
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
        borderRadius:
            BorderRadius.circular(18),
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
              fontWeight:
                  FontWeight.bold,
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
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor:
                color.withValues(
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
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
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
  // DIALOG ERROR
  // ============================================================

  void _showDialogError(
    BuildContext dialogContext,
    String message,
  ) {
    ScaffoldMessenger.of(
      dialogContext,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
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
    final text =
        value?.toString().trim() ?? '';

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
    final message =
        error.toString().trim();

    if (message.isEmpty) {
      return 'An unexpected error occurred.';
    }

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }
}