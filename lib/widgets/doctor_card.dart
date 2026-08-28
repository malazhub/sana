import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/doctor.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const DoctorCard({super.key, required this.doctor});

  Future<void> _call(String phone) async {
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
    final phone = doctor.phone?.trim() ?? '';

    return Card(
      child: ListTile(
        title: Text(doctor.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doctor.specialty != null && doctor.specialty!.isNotEmpty)
              Text(doctor.specialty!),
            if (phone.isNotEmpty) Text(phone),
          ],
        ),
        trailing: phone.isEmpty
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Call',
                    icon: const Icon(Icons.phone, color: Colors.teal),
                    onPressed: () => _call(phone),
                  ),
                  IconButton(
                    tooltip: 'WhatsApp',
                    icon: const Icon(Icons.chat, color: Colors.green),
                    onPressed: () => _whatsapp(phone),
                  ),
                ],
              ),
      ),
    );
  }
}
