import 'package:flutter/material.dart';
import '../models/doctor.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;

  const DoctorCard({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(doctor.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (doctor.specialty != null && doctor.specialty!.isNotEmpty)
              Text(doctor.specialty!),
            if (doctor.phone != null && doctor.phone!.isNotEmpty)
              Text(doctor.phone!),
          ],
        ),
      ),
    );
  }
}