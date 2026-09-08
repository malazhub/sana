import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pharmacy.dart';

class PharmacyCard extends StatelessWidget {
  final Pharmacy pharmacy;
  final VoidCallback onDelete;

  const PharmacyCard({
    super.key,
    required this.pharmacy,
    required this.onDelete,
  });

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsapp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final normalized = clean.startsWith('+') ? clean.substring(1) : clean;
    final uri = Uri.parse('https://wa.me/$normalized');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = pharmacy.name;
    final phone = pharmacy.phone?.trim() ?? '';
    final address = pharmacy.address?.trim() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'P',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phone.isNotEmpty) Text('ðŸ“ž $phone'),
            if (address.isNotEmpty) Text('ðŸ“ $address'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (phone.isNotEmpty)
              IconButton(
                tooltip: 'Call',
                icon: const Icon(Icons.phone, color: Colors.teal),
                onPressed: () => _callPhone(phone),
              ),
            if (phone.isNotEmpty)
              IconButton(
                tooltip: 'WhatsApp',
                icon: const Icon(Icons.chat, color: Colors.green),
                onPressed: () => _whatsapp(phone),
              ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
