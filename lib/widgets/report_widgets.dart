import 'package:flutter/material.dart';

Widget buildCard({
  required String title,
required List<Widget> children,
}){
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
        style: TextStyle(fontSize: 18,
        fontWeight: FontWeight.bold,)
        ),
const SizedBox(height: 12,),
        ...children,
      ],
    ),
    ),
  );
}

Widget buildField(
TextEditingController ctrl,
String label,
IconData icon, {
  TextInputType type = TextInputType.text,
}) {
  return Padding(padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
  );
}