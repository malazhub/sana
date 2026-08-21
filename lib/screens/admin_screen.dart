import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({
    super.key,
  });

  @override
  State<AdminScreen> createState() =>
      _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  Future<void> _signOut() async {
    final AuthProvider auth =
        context.read<AuthProvider>();

    await auth.signOut();

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  void _goBack() {
    Navigator.of(context).maybePop();
  }

  void _showMessage({
    required String title,
    required String message,
    required IconData icon,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
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
                  color:
                      theme.colorScheme.primary,
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
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(
                        sheetContext,
                      ).pop();
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

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth =
        context.watch<AuthProvider>();

    /*
     * Safety check:
     *
     * AdminScreen must only be usable while the
     * authenticated profile has role == admin.
     */
    if (!auth.isAuthenticated || !auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Administrator',
          ),
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
                    Navigator.of(context)
                        .popUntil(
                      (route) => route.isFirst,
                    );
                  },
                  child: const Text(
                    'Return Home',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFFF4FAF9),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF009688),
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: _goBack,
        ),

        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.admin_panel_settings,
            ),
            SizedBox(width: 10),
            Text(
              'Admin Panel',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        centerTitle: true,

        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(
              Icons.logout,
            ),
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

      bottomNavigationBar:
          NavigationBar(
        selectedIndex:
            _selectedIndex,

        onDestinationSelected:
            (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
            ),
            selectedIcon: Icon(
              Icons.dashboard,
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.people_outline,
            ),
            selectedIcon: Icon(
              Icons.people,
            ),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.bar_chart_outlined,
            ),
            selectedIcon: Icon(
              Icons.bar_chart,
            ),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.security_outlined,
            ),
            selectedIcon: Icon(
              Icons.security,
            ),
            label: 'Security',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final AuthProvider auth =
        context.watch<AuthProvider>();

    final String email =
        auth.currentUser?.email ??
            'Administrator';

    return SafeArea(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(
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
                color:
                    Color(0xFF008F83),
                fontSize: 27,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            _buildAdminTile(
              icon: Icons.people,
              iconColor: Colors.blue,
              backgroundColor:
                  const Color(0xFFE0F0FA),
              title:
                  'User Management',
              subtitle:
                  'Manage SANA users and accounts.',
              onTap: () {
                _showMessage(
                  title:
                      'User Management',
                  message:
                      'Manage SANA users, activation status, and administrator access from this section.',
                  icon: Icons.people,
                );
              },
            ),

            const SizedBox(height: 12),

            _buildAdminTile(
              icon:
                  Icons.bar_chart,
              iconColor:
                  Colors.indigo,
              backgroundColor:
                  const Color(0xFFE6EAF8),
              title:
                  'Application Statistics',
              subtitle:
                  'View application activity and statistics.',
              onTap: () {
                _showMessage(
                  title:
                      'Application Statistics',
                  message:
                      'Application statistics can be connected to your existing database data.',
                  icon:
                      Icons.bar_chart,
                );
              },
            ),

            const SizedBox(height: 12),

            _buildAdminTile(
              icon:
                  Icons.security,
              iconColor:
                  Colors.red,
              backgroundColor:
                  const Color(0xFFFBE4E1),
              title: 'Security',
              subtitle:
                  'Review administrator and security settings.',
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
            ),

            const SizedBox(height: 12),

            _buildAdminTile(
              icon:
                  Icons.settings,
              iconColor:
                  Colors.orange,
              backgroundColor:
                  const Color(0xFFFFF1D8),
              title:
                  'Application Settings',
              subtitle:
                  'Configure administrator application options.',
              onTap: () {
                _showMessage(
                  title:
                      'Application Settings',
                  message:
                      'Administrator application settings can be added here without changing the authentication flow.',
                  icon:
                      Icons.settings,
                );
              },
            ),

            const SizedBox(height: 28),

            const Divider(),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child:
                  OutlinedButton.icon(
                onPressed:
                    _signOut,
                icon: const Icon(
                  Icons.logout,
                ),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.red.shade700,
                  side: BorderSide(
                    color:
                        Colors.red.shade400,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
    String email,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF008F83),
            Color(0xFF009688),
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.teal.withValues(
              alpha: 0.22,
            ),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
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
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Manage and monitor your SANA application.',
            style: TextStyle(
              color:
                  Color(0xFFD5F5F1),
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
                  .withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
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
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
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
          padding:
              const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color:
                  Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withValues(
                  alpha: 0.06,
                ),
                blurRadius: 5,
                offset:
                    const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration:
                    BoxDecoration(
                  color:
                      backgroundColor,
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 34,
                  color:
                      iconColor,
                ),
              ),

              const SizedBox(
                width: 18,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
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

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      subtitle,
                      style:
                          TextStyle(
                        color:
                            Colors.grey
                                .shade600,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color:
                    Colors.grey.shade500,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersPage() {
    return SafeArea(
      child: SingleChildScrollView(
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
                  'Manage SANA user accounts.',
            ),

            const SizedBox(
              height: 20,
            ),

            _buildInfoCard(
              icon:
                  Icons.person_add,
              title:
                  'User Accounts',
              text:
                  'User management is connected to the existing authentication and users table.',
            ),

            const SizedBox(
              height: 12,
            ),

            _buildInfoCard(
              icon:
                  Icons.verified_user,
              title:
                  'Account Activation',
              text:
                  'Review and manage account activation status from the administrator area.',
            ),

            const SizedBox(
              height: 12,
            ),

            _buildInfoCard(
              icon:
                  Icons.admin_panel_settings,
              title:
                  'Administrator Access',
              text:
                  'Administrator authentication uses AuthProvider and requires role == admin.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsPage() {
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
                  Icons.bar_chart,
              title:
                  'Application Statistics',
              subtitle:
                  'Application activity overview.',
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
                    title: 'Users',
                    value: '—',
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child:
                      _buildStatCard(
                    icon:
                        Icons.login,
                    title: 'Logins',
                    value: '—',
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
                        Icons.check_circle,
                    title: 'Active',
                    value: '—',
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child:
                      _buildStatCard(
                    icon:
                        Icons.pending,
                    title: 'Pending',
                    value: '—',
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
                  'Statistics',
              text:
                  'The statistics area is intentionally kept independent from authentication so it does not interfere with administrator login.',
            ),
          ],
        ),
      ),
    );
  }

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
              title: 'Security',
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
                  'Protected by the existing AuthProvider authentication flow.',
              color:
                  Colors.green,
            ),

            const SizedBox(
              height: 12,
            ),

            _buildSecurityTile(
              icon:
                  Icons.key,
              title:
                  'Administrator Login',
              subtitle:
                  'The administrator login credentials are checked through Supabase authentication.',
              color:
                  Colors.orange,
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
                  'Access is granted only when users.role is exactly admin.',
              color:
                  Colors.blue,
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
                  Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
      decoration: BoxDecoration(
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
                Colors.white
                    .withValues(
              alpha: 0.18,
            ),
            child: Icon(
              icon,
              color: Colors.white,
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  style:
                      TextStyle(
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

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
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
            style:
                TextStyle(
              color:
                  Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

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
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: color,
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
                  style:
                      TextStyle(
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