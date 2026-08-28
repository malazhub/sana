import 'package:flutter/material.dart';

class MedicationCard extends StatelessWidget {
  final String medicationName;
  final String dosage;

  const MedicationCard({
    Key? key,
    required this.medicationName,
    required this.dosage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(medicationName),
        subtitle: Text(dosage),
      ),
    );
  }
}
