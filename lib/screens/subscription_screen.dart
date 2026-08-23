import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final expiry = auth.expiryDate;
    final daysRemaining = auth.daysRemaining;

    final bool expired =
        auth.subscriptionExpired;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subscription',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // --------------------------------------------------
                  // ICON
                  // --------------------------------------------------

                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(
                        alpha: 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      expired
                          ? Icons
                              .event_busy_outlined
                          : Icons
                              .hourglass_empty_outlined,
                      size: 48,
                      color: Colors.teal,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --------------------------------------------------
                  // TITLE
                  // --------------------------------------------------

                  Text(
                    expired
                        ? 'Subscription Expired'
                        : 'Subscription Required',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    expired
                        ? 'Your SANA subscription has expired. Please contact the administrator to renew your access.'
                        : 'Your account has been created, but access to SANA requires an active subscription.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --------------------------------------------------
                  // ACCOUNT CARD
                  // --------------------------------------------------

                  _buildAccountCard(
                    context,
                    auth,
                  ),

                  const SizedBox(height: 16),

                  // --------------------------------------------------
                  // SUBSCRIPTION STATUS
                  // --------------------------------------------------

                  _buildStatusCard(
                    context,
                    expired: expired,
                    expiry: expiry,
                    daysRemaining: daysRemaining,
                  ),

                  const SizedBox(height: 24),

                  // --------------------------------------------------
                  // INFORMATION
                  // --------------------------------------------------

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            Colors.teal.shade100,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How activation works',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '1. Your account is created securely.',
                        ),
                        SizedBox(height: 6),
                        Text(
                          '2. An administrator confirms your payment.',
                        ),
                        SizedBox(height: 6),
                        Text(
                          '3. The server activates your subscription.',
                        ),
                        SizedBox(height: 6),
                        Text(
                          '4. Your one-year expiry date is calculated by the backend.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --------------------------------------------------
                  // REFRESH
                  // --------------------------------------------------

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              await context
                                  .read<AuthProvider>()
                                  .refresh();
                            },
                      icon: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.refresh,
                            ),
                      label: Text(
                        auth.isLoading
                            ? 'Checking...'
                            : 'Check Subscription Status',
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --------------------------------------------------
                  // SIGN OUT
                  // --------------------------------------------------

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              await context
                                  .read<AuthProvider>()
                                  .signOut();
                            },
                      icon: const Icon(
                        Icons.logout,
                      ),
                      label: const Text(
                        'Sign Out',
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACCOUNT CARD
  // ============================================================

  Widget _buildAccountCard(
    BuildContext context,
    AuthProvider auth,
  ) {
    final name =
        auth.profile?['name']
                ?.toString()
                .trim() ??
            '';

    final email =
        auth.profile?['email']
                ?.toString()
                .trim() ??
            auth.email;

    final phone =
        auth.profile?['phone']
                ?.toString()
                .trim() ??
            '';

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
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),

          if (name.isNotEmpty)
            _buildInfoRow(
              Icons.person_outline,
              'Name',
              name,
            ),

          _buildInfoRow(
            Icons.email_outlined,
            'Email',
            email.isEmpty
                ? 'Not available'
                : email,
          ),

          if (phone.isNotEmpty)
            _buildInfoRow(
              Icons.phone_outlined,
              'Phone',
              phone,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _buildStatusCard(
    BuildContext context, {
    required bool expired,
    required DateTime? expiry,
    required int? daysRemaining,
  }) {
    final Color color =
        expired
            ? Colors.red
            : Colors.orange;

    String status;

    if (expired) {
      status = 'Expired';
    } else {
      status = 'Pending activation';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                expired
                    ? Icons.cancel_outlined
                    : Icons
                        .hourglass_top_outlined,
                color: color,
              ),
              const SizedBox(width: 10),
              Text(
                status,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),

          if (expiry != null) ...[
            const SizedBox(height: 14),

            _buildInfoRow(
              Icons.event_outlined,
              'Expiry date',
              _formatDate(expiry),
            ),

            if (!expired &&
                daysRemaining != null)
              _buildInfoRow(
                Icons.schedule_outlined,
                'Days remaining',
                '$daysRemaining days',
              ),
          ] else ...[
            const SizedBox(height: 14),
            Text(
              'No active subscription expiry date is currently recorded.',
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    final local =
        date.toLocal();

    final day =
        local.day.toString().padLeft(
              2,
              '0',
            );

    final month =
        local.month.toString().padLeft(
              2,
              '0',
            );

    final year =
        local.year.toString();

    return '$day/$month/$year';
  }
}