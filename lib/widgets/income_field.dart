//widgets/income_field.dart
import 'package:flutter/material.dart'; 

class IncomeField extends StatelessWidget { 
  final TextEditingController controller; 
  final String label; 
  final void Function(String)? onChanged; 
  final TextInputType keyboardType;
  
  const IncomeField({ 
    super.key, 
    required this.controller, 
    required this.label, 
    this.onChanged, 
    this.keyboardType = TextInputType.number,
  }); 
  
  @override 
  Widget build(BuildContext context) { 
    return TextField( 
      controller: controller, 
      keyboardType: keyboardType, 
      decoration: InputDecoration( 
        labelText: label, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ), 
      onChanged: onChanged, 
    ); 
  } 
}
