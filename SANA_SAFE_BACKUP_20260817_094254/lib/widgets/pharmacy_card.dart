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

  @override
  Widget build(BuildContext context) {
    final String name = pharmacy.name;
    final String? phone = pharmacy.phone;
    final String? address = pharmacy.address;

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
            if (phone != null && phone.isNotEmpty) Text('📞 $phone'),
            if (address != null && address.isNotEmpty) Text('📍 $address'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: () {
          if (phone != null && phone.isNotEmpty) {
            _callPhone(phone);
          }
        },
      ),
    );
  }

  void _callPhone(String phone) async {
    final Uri phoneUri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
}
