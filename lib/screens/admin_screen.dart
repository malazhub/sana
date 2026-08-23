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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AdminProvider>().loadUsers();
    });
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> _signOut() async {
    final auth = context.read<AuthProvider>();

    await auth.signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
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
                  onPressed: () {
                    Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    );
                  },
                  child: const Text('Return Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
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
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
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
    final auth = context.watch<AuthProvider>();

    final email =
        auth.currentUser?.email ?? 'Administrator';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          28,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(email),
            const SizedBox(height: 28),
            const Text(
              'Administration',
              style: TextStyle(
                color: Color(0xFF008F83),
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            _buildAdminTile(
              icon: Icons.people,
              iconColor: Colors.blue,
              backgroundColor:
                  const Color(0xFFE0F0FA),
              title: 'User Management',
              subtitle:
                  'Manage SANA users and confirm payments.',
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });

                context
                    .read<AdminProvider>()
                    .loadUsers();
              },
            ),

            const SizedBox(height: 12),

            _buildAdminTile(
              icon: Icons.bar_chart,
              iconColor: Colors.indigo,
              backgroundColor:
                  const Color(0xFFE6EAF8),
              title: 'Application Statistics',
              subtitle:
                  'View application activity and statistics.',
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),

            const SizedBox(height: 12),

            _buildAdminTile(
              icon: Icons.security,
              iconColor: Colors.red,
              backgroundColor:
                  const Color(0xFFFBE4E1),
              title: 'Security',
              subtitle:
                  'Review administrator security settings.',
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.red.shade700,
                  side: BorderSide(
                    color: Colors.red.shade400,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF008F83),
            Color(0xFF009688),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.teal.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user,
            color: Colors.white,
            size: 52,
          ),
          const SizedBox(height: 20),
          const Text(
            'Administrator Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage and monitor your SANA application.',
            style: TextStyle(
              color: Color(0xFFD5F5F1),
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTile({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.06),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  size: 34,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade500,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // USERS PAGE
  // ============================================================

  Widget _buildUsersPage() {
    return SafeArea(
      child: Consumer<AdminProvider>(
        builder: (context, admin, child) {
          if (admin.isLoading &&
              admin.users.isEmpty) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (admin.errorMessage != null &&
              admin.users.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      admin.errorMessage!,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed:
                          admin.loadUsers,
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label:
                          const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: admin.loadUsers,
            child: SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(
                    icon: Icons.people,
                    title:
                        'User Management',
                    subtitle:
                        'Manage SANA user accounts and confirm payments.',
                  ),
                  const SizedBox(height: 20),

                  if (admin.errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin:
                          const EdgeInsets.only(
                        bottom: 16,
                      ),
                      padding:
                          const EdgeInsets.all(14),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.red.shade50,
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                        border: Border.all(
                          color:
                              Colors.red.shade200,
                        ),
                      ),
                      child: Text(
                        admin.errorMessage!,
                        style: TextStyle(
                          color:
                              Colors.red.shade800,
                        ),
                      ),
                    ),

                  if (admin.users.isEmpty)
                    _buildInfoCard(
                      icon:
                          Icons.people_outline,
                      title: 'No Users',
                      text:
                          'No registered user accounts are currently available.',
                    )
                  else
                    _buildUsersTable(admin),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // USERS TABLE
  // ============================================================

  Widget _buildUsersTable(
    AdminProvider admin,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor:
              const WidgetStatePropertyAll(
            Color(0xFFEAF7F5),
          ),
          columns: const [
            DataColumn(
              label: Text(
                'User ID',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Name',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Email',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Phone',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Joining Date',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Expiry Date',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Payment',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Action',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: admin.users.map((user) {
            /*
             * AdminProvider loads the customer ID
             * under "id".
             */
            final userId =
                user['id']?.toString() ?? '';

            final name =
                user['name']?.toString() ?? '';

            final email =
                user['payment_user_email']
                        ?.toString() ??
                    user['email']?.toString() ??
                    '';

            final phone =
                user['payment_user_phone']
                        ?.toString() ??
                    user['phone']?.toString() ??
                    '';

            final joiningDate =
                _formatDate(
              user[
                    'subscription_activated_at'] ??
                  user['created_at'],
            );

            final expiryDate =
                _formatDate(
              user[
                    'subscription_expires_at'] ??
                  user['expiry_date'],
            );

            final status =
                admin.statusText(user);

            final payment =
                _paymentText(user);

            final active =
                admin.isActive(user);

            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      userId,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 130,
                    child: Text(
                      name.isEmpty
                          ? '—'
                          : name,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      email.isEmpty
                          ? '—'
                          : email,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 130,
                    child: Text(
                      phone.isEmpty
                          ? '—'
                          : phone,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Text(joiningDate),
                ),
                DataCell(
                  Text(expiryDate),
                ),
                DataCell(
                  _buildStatusChip(status),
                ),
                DataCell(
                  _buildStatusChip(payment),
                ),
                DataCell(
                  _buildUserAction(
                    admin: admin,
                    userId: userId,
                    active: active,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT TEXT
  // ============================================================

  String _paymentText(
    Map<String, dynamic> user,
  ) {
    final status =
        user['subscription_status']
            ?.toString()
            .trim()
            .toLowerCase();

    if (status == 'active') {
      return 'Paid';
    }

    if (status == 'pending') {
      return 'Pending';
    }

    if (status == 'expired') {
      return 'Expired';
    }

    return 'Unpaid';
  }

  // ============================================================
  // USER ACTION
  // ============================================================

  Widget _buildUserAction({
    required AdminProvider admin,
    required String userId,
    required bool active,
  }) {
    if (active) {
      return OutlinedButton.icon(
        onPressed: admin.isLoading
            ? null
            : () {
                _deactivateUser(
                  admin,
                  userId,
                );
              },
        icon: const Icon(
          Icons.block,
          size: 18,
        ),
        label:
            const Text('Deactivate'),
      );
    }

    return FilledButton.icon(
      onPressed: admin.isLoading
          ? null
          : () {
              _confirmPayment(
                admin,
                userId,
              );
            },
      icon: const Icon(
        Icons.payment,
        size: 18,
      ),
      label:
          const Text('Confirm Payment'),
    );
  }

  // ============================================================
  // CONFIRM PAYMENT
  // ============================================================

  Future<void> _confirmPayment(
    AdminProvider admin,
    String userId,
  ) async {
    final transactionController =
        TextEditingController();

    final amountController =
        TextEditingController();

    final currencyController =
        TextEditingController(
      text: 'USD',
    );

    final notesController =
        TextEditingController();

    final formKey =
        GlobalKey<FormState>();

    final result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.payment),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Confirm Payment',
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter the payment details below. '
                      'After confirmation, the server will '
                      'activate the account for exactly one year.',
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller:
                          transactionController,
                      textInputAction:
                          TextInputAction.next,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Transaction ID',
                        hintText:
                            'Payment transaction/reference ID',
                        prefixIcon:
                            Icon(Icons.receipt_long),
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? '')
                            .trim()
                            .isEmpty) {
                          return 'Transaction ID is required.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          amountController,
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
                            'Payment Amount',
                        hintText:
                            'Enter amount',
                        prefixIcon:
                            Icon(Icons.attach_money),
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final amount =
                            double.tryParse(
                          (value ?? '')
                              .trim(),
                        );

                        if (amount == null ||
                            amount <= 0) {
                          return 'Enter a valid payment amount.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          currencyController,
                      textCapitalization:
                          TextCapitalization.characters,
                      textInputAction:
                          TextInputAction.next,
                      decoration:
                          const InputDecoration(
                        labelText: 'Currency',
                        hintText: 'USD',
                        prefixIcon:
                            Icon(Icons.currency_exchange),
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? '')
                            .trim()
                            .isEmpty) {
                          return 'Currency is required.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller:
                          notesController,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Notes (optional)',
                        hintText:
                            'Optional payment notes',
                        prefixIcon:
                            Icon(Icons.notes),
                        border:
                            OutlineInputBorder(),
                        alignLabelWithHint:
                            true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            FilledButton.icon(
              onPressed: () {
                if (!formKey.currentState!
                    .validate()) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              icon: const Icon(
                Icons.check_circle,
              ),
              label: const Text(
                'Confirm Payment',
              ),
            ),
          ],
        );
      },
    );

    if (result != true) {
      transactionController.dispose();
      amountController.dispose();
      currencyController.dispose();
      notesController.dispose();
      return;
    }

    final transactionId =
        transactionController.text.trim();

    final amount =
        double.tryParse(
      amountController.text.trim(),
    );

    final currency =
        currencyController.text
            .trim()
            .toUpperCase();

    final notes =
        notesController.text.trim();

    transactionController.dispose();
    amountController.dispose();
    currencyController.dispose();
    notesController.dispose();

    if (amount == null || amount <= 0) {
      _showMessage(
        title: 'Invalid Payment',
        message:
            'The payment amount is invalid.',
        icon: Icons.error_outline,
      );
      return;
    }

    final success =
        await admin.activateUser(
      userId,
      transactionId: transactionId,
      amount: amount,
      currency: currency,
      paidAt: DateTime.now().toUtc(),
      notes: notes.isEmpty
          ? null
          : notes,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage(
        title: 'Payment Confirmed',
        message:
            'Payment confirmed successfully. '
            'The customer account is now active for '
            'exactly one year. The server calculated '
            'the activation and expiry dates.',
        icon:
            Icons.verified_user,
      );
    } else {
      _showMessage(
        title: 'Payment Confirmation Failed',
        message:
            admin.errorMessage ??
                'Unable to confirm the payment.',
        icon:
            Icons.error_outline,
      );
    }
  }

  // ============================================================
  // DEACTIVATE USER
  // ============================================================

  Future<void> _deactivateUser(
    AdminProvider admin,
    String userId,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Deactivate User',
          ),
          content: const Text(
            'Deactivate this user account?\n\n'
            'No documents, medications, doctors, or '
            'other user data will be deleted.',
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

    if (confirmed != true) {
      return;
    }

    final success =
        await admin.deactivateUser(
      userId,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage(
        title:
            'Account Deactivated',
        message:
            'The user account has been deactivated. '
            'The user data remains stored.',
        icon:
            Icons.pause_circle_outline,
      );
    } else {
      _showMessage(
        title:
            'Deactivation Failed',
        message:
            admin.errorMessage ??
                'Unable to deactivate this user.',
        icon:
            Icons.error_outline,
      );
    }
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(
    String text,
  ) {
    final normalized =
        text.trim().toLowerCase();

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;

    if (normalized == 'active' ||
        normalized == 'paid') {
      backgroundColor =
          Colors.green.shade50;
      foregroundColor =
          Colors.green.shade800;
      icon =
          Icons.check_circle_outline;
    } else if (normalized == 'pending') {
      backgroundColor =
          Colors.orange.shade50;
      foregroundColor =
          Colors.orange.shade800;
      icon =
          Icons.pending_outlined;
    } else if (normalized == 'expired') {
      backgroundColor =
          Colors.red.shade50;
      foregroundColor =
          Colors.red.shade800;
      icon =
          Icons.timer_off_outlined;
    } else {
      backgroundColor =
          Colors.grey.shade100;
      foregroundColor =
          Colors.grey.shade800;
      icon =
          Icons.remove_circle_outline;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: foregroundColor,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color:
                  foregroundColor,
              fontWeight:
                  FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
    dynamic value,
  ) {
    final date =
        _parseDate(value);

    if (date == null) {
      return '—';
    }

    final local =
        date.toLocal();

    final month =
        local.month
            .toString()
            .padLeft(2, '0');

    final day =
        local.day
            .toString()
            .padLeft(2, '0');

    return '${local.year}-$month-$day';
  }

  DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatisticsPage() {
    return SafeArea(
      child: Consumer<AdminProvider>(
        builder: (
          context,
          admin,
          child,
        ) {
          final total =
              admin.users.length;

          final active =
              admin.users
                  .where(
                    admin.isActive,
                  )
                  .length;

          final pending =
              admin.users
                  .where(
                    (user) =>
                        admin.statusText(
                          user,
                        ) ==
                        'Pending',
                  )
                  .length;

          final expired =
              admin.users
                  .where(
                    admin.isExpired,
                  )
                  .length;

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildPageHeader(
                  icon:
                      Icons.bar_chart,
                  title:
                      'Application Statistics',
                  subtitle:
                      'Current SANA user subscription overview.',
                ),
                const SizedBox(
                  height: 20,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          _buildStatCard(
                        icon:
                            Icons.people,
                        title:
                            'Users',
                        value:
                            '$total',
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child:
                          _buildStatCard(
                        icon:
                            Icons.check_circle,
                        title:
                            'Active',
                        value:
                            '$active',
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          _buildStatCard(
                        icon:
                            Icons.pending,
                        title:
                            'Pending',
                        value:
                            '$pending',
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child:
                          _buildStatCard(
                        icon:
                            Icons.timer_off,
                        title:
                            'Expired',
                        value:
                            '$expired',
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                _buildInfoCard(
                  icon:
                      Icons.info_outline,
                  title:
                      'Subscription System',
                  text:
                      'Payment confirmation is performed '
                      'by the administrator through this screen. '
                      'The protected server-side RPC calculates '
                      'the activation and expiry dates.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SECURITY
  // ============================================================

  Widget _buildSecurityPage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildPageHeader(
              icon:
                  Icons.security,
              title:
                  'Security',
              subtitle:
                  'Administrator security information.',
            ),
            const SizedBox(
              height: 20,
            ),

            _buildSecurityTile(
              icon:
                  Icons.lock,
              title:
                  'Administrator Authentication',
              subtitle:
                  'Administrator access requires an authenticated Supabase session.',
              color:
                  Colors.green,
            ),

            const SizedBox(
              height: 12,
            ),

            _buildSecurityTile(
              icon:
                  Icons.verified_user,
              title:
                  'Admin Role',
              subtitle:
                  'Access is granted only when the server-side users.role value is admin.',
              color:
                  Colors.blue,
            ),

            const SizedBox(
              height: 12,
            ),

            _buildSecurityTile(
              icon:
                  Icons.payment,
              title:
                  'Payment Confirmation',
              subtitle:
                  'Administrators confirm customer payments directly from the User Management screen.',
              color:
                  Colors.orange,
            ),

            const SizedBox(
              height: 12,
            ),

            _buildSecurityTile(
              icon:
                  Icons.key,
              title:
                  'One-Year Activation',
              subtitle:
                  'The protected server-side RPC calculates the subscription expiry. Flutter does not choose the expiry date.',
              color:
                  Colors.deepOrange,
            ),

            const SizedBox(
              height: 12,
            ),

            _buildSecurityTile(
              icon:
                  Icons.delete_outline,
              title:
                  'Non-Destructive Deactivation',
              subtitle:
                  'Deactivating an account does not delete user data.',
              color:
                  Colors.red,
            ),

            const SizedBox(
              height: 12,
            ),

            _buildSecurityTile(
              icon:
                  Icons.logout,
              title:
                  'Session Control',
              subtitle:
                  'Sign Out terminates the current administrator Supabase session.',
              color:
                  Colors.purple,
            ),
          ],
        ),
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
      padding:
          const EdgeInsets.all(22),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF008F83),
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
              color:
                  Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 22,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(
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
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                const Color(0xFF008F83),
            size: 30,
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
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
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                const Color(0xFF008F83),
            size: 30,
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            value,
            style:
                const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            title,
            style: TextStyle(
              color:
                  Colors.grey.shade600,
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
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.grey.shade200,
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
              color:
                  color,
            ),
          ),
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
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
}