import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _search = '';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredUsers(
    List<Map<String, dynamic>> users,
  ) {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) {
      return users;
    }

    return users.where((user) {
      final values = [
        user['user_id'],
        user['user_name'],
        user['user_email'],
        user['user_phone'],
        user['subscription_status'],
      ];

      return values.any(
        (value) => value
            ?.toString()
            .toLowerCase()
            .contains(query),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    final users = _filteredUsers(provider.users);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text(
          'SANA Admin Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: provider.isLoading
                ? null
                : () {
                    context.read<AdminProvider>().refresh();
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStats(provider.users),
          _buildSearch(),

          if (provider.errorMessage != null)
            _buildError(provider.errorMessage!),

          Expanded(
            child: provider.isLoading && provider.users.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : users.isEmpty
                    ? const Center(
                        child: Text('No users found.'),
                      )
                    : _buildTable(users, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(
    List<Map<String, dynamic>> users,
  ) {
    final provider = context.read<AdminProvider>();

    final active =
        users.where(provider.isActive).length;

    final expired =
        users.where(provider.isExpired).length;

    final pending =
        users.length - active - expired;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.teal.shade700,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;

          final items = [
            _statItem('TOTAL', users.length.toString()),
            _statItem('ACTIVE', active.toString()),
            _statItem('PENDING', pending.toString()),
            _statItem('EXPIRED', expired.toString()),
          ];

          return compact
              ? Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 28,
                  runSpacing: 12,
                  children: items,
                )
              : Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: items,
                );
        },
      ),
    );
  }

  Widget _statItem(
    String label,
    String value,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _search = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _search = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    List<Map<String, dynamic>> users,
    AdminProvider provider,
  ) {
    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStatePropertyAll(
              Colors.teal.shade50,
            ),
            columnSpacing: 24,
            horizontalMargin: 16,
            columns: const [
              DataColumn(label: Text('User ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Joined')),
              DataColumn(label: Text('Expiry')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Action')),
            ],
            rows: users.map((user) {
              return _buildRow(user, provider);
            }).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(
    Map<String, dynamic> user,
    AdminProvider provider,
  ) {
    final active = provider.isActive(user);
    final expired = provider.isExpired(user);

    final userId =
        user['user_id']?.toString() ?? '';

    final name =
        user['user_name']?.toString() ?? 'No Name';

    final email =
        user['user_email']?.toString() ?? 'No Email';

    final phone =
        user['user_phone']?.toString() ?? 'No Phone';

    final created =
        _parseDate(user['created_at']);

    final expiry =
        _parseDate(
          user['expires_at'] ??
              user['expiry_date'],
        );

    final status =
        provider.statusText(user);

    return DataRow(
      cells: [
        DataCell(
          Text(
            userId.length > 8
                ? userId.substring(0, 8)
                : userId,
            style: const TextStyle(
              fontFamily: 'monospace',
            ),
          ),
        ),
        DataCell(Text(name)),
        DataCell(Text(email)),
        DataCell(Text(phone)),
        DataCell(
          Text(
            created == null
                ? '-'
                : DateFormat('yyyy-MM-dd').format(created),
          ),
        ),
        DataCell(
          Text(
            expiry == null
                ? '-'
                : DateFormat('yyyy-MM-dd').format(expiry),
            style: TextStyle(
              color: expired
                  ? Colors.red
                  : Colors.black,
              fontWeight:
                  expired ? FontWeight.bold : null,
            ),
          ),
        ),
        DataCell(
          _statusChip(
            status,
            active,
            expired,
          ),
        ),
        DataCell(
          active
              ? OutlinedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () => _deactivate(user),
                  child: const Text('DEACTIVATE'),
                )
              : FilledButton(
                  onPressed: provider.isLoading
                      ? null
                      : () => _activate(user),
                  child: Text(
                    expired
                        ? 'REACTIVATE'
                        : 'ACTIVATE',
                  ),
                ),
        ),
      ],
    );
  }

  Widget _statusChip(
    String status,
    bool active,
    bool expired,
  ) {
    final Color background;
    final Color foreground;

    if (active) {
      background = Colors.green.shade100;
      foreground = Colors.green.shade900;
    } else if (expired) {
      background = Colors.red.shade100;
      foreground = Colors.red.shade900;
    } else {
      background = Colors.orange.shade100;
      foreground = Colors.orange.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _activate(
    Map<String, dynamic> user,
  ) async {
    final userId =
        user['user_id']?.toString() ?? '';

    if (userId.isEmpty) {
      return;
    }

    final transactionController =
        TextEditingController();

    final amountController =
        TextEditingController();

    final currencyController =
        TextEditingController(text: 'USD');

    final notesController =
        TextEditingController();

    try {
      final result =
          await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Activate User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user['user_name']
                            ?.toString() ??
                        user['user_email']
                            ?.toString() ??
                        'User',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller:
                        transactionController,
                    decoration:
                        const InputDecoration(
                      labelText: 'Transaction ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller:
                        currencyController,
                    decoration:
                        const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration:
                        const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext)
                      .pop(false);
                },
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext)
                      .pop(true);
                },
                child: const Text('ACTIVATE'),
              ),
            ],
          );
        },
      );

      if (result != true || !mounted) {
        return;
      }

      final amount =
          double.tryParse(
        amountController.text.trim(),
      );

      if (amount == null || amount <= 0) {
        _showMessage(
          'Enter a valid payment amount.',
        );
        return;
      }

      final transactionId =
          transactionController.text.trim();

      final currency =
          currencyController.text.trim();

      if (transactionId.isEmpty) {
        _showMessage(
          'Transaction ID is required.',
        );
        return;
      }

      if (currency.isEmpty) {
        _showMessage(
          'Currency is required.',
        );
        return;
      }

      final success =
          await context.read<AdminProvider>()
              .activateUser(
                userId,
                transactionId: transactionId,
                amount: amount,
                currency: currency,
                paidAt: DateTime.now().toUtc(),
                notes: notesController.text.trim(),
              );

      if (!mounted) {
        return;
      }

      if (!success) {
        _showMessage(
          context
                  .read<AdminProvider>()
                  .errorMessage ??
              'Unable to activate user.',
        );
      }
    } finally {
      transactionController.dispose();
      amountController.dispose();
      currencyController.dispose();
      notesController.dispose();
    }
  }

  Future<void> _deactivate(
    Map<String, dynamic> user,
  ) async {
    final userId =
        user['user_id']?.toString() ?? '';

    if (userId.isEmpty) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Deactivate User'),
          content: const Text(
            'The user will lose active subscription access. No application data will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text('CANCEL'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text('DEACTIVATE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success =
        await context
            .read<AdminProvider>()
            .deactivateUser(userId);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        context
                .read<AdminProvider>()
                .errorMessage ??
            'Unable to deactivate user.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value.toLocal();
    }

    final parsed =
        DateTime.tryParse(value.toString());

    return parsed?.toLocal();
  }
}