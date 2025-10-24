//pages/exempt_income_page.dart
import 'package:flutter/material.dart'; 
import '../widgets/income_field.dart'; 
import '../services/tax_data_service.dart'; 

class ExemptIncomePage extends StatefulWidget { 
  const ExemptIncomePage({super.key}); 

  @override 
  State<ExemptIncomePage> createState() => _ExemptIncomePageState(); 
} 

class _ExemptIncomePageState extends State<ExemptIncomePage> { 
  final TaxDataService service = TaxDataService(); 
  final TextEditingController exemptCtrl = TextEditingController(); 

  @override 
  void initState() { 
    super.initState(); 
    // Initialize controller with current in-memory value
    exemptCtrl.text = service.exemptIncome.toStringAsFixed(2); 
  } 

  void saveExemptIncome() { 
    service.exemptIncome = double.tryParse(exemptCtrl.text) ?? 0.0; 
    
    // --- LOCAL STATE MANAGEMENT (No Firestore save) ---
    if (mounted) { 
      ScaffoldMessenger.of(context).showSnackBar( 
        const SnackBar(content: Text("Exempt/Excluded income saved locally")), 
      ); 
      Navigator.pop(context); 
    } 
  } 

  @override 
  Widget build(BuildContext context) { 
    const primaryColor = Color(0xFF38E07B);
    const neutral900 = Color(0xFF111714);
    const accentGreen = Color(0xFF10B981);
    
    return Scaffold( 
      body: SafeArea(
        child: Padding( 
          padding: const EdgeInsets.all(24.0), 
          child: Column( 
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [ 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text( 
                    "Exempt/Excluded Income", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: neutral900), 
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor.withOpacity(0.5)),
                      ),
                      child: Icon(Icons.close_rounded, color: primaryColor, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter total exempt/excluded income (local & foreign)",
                style: TextStyle(fontSize: 14, color: accentGreen, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24), 
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: IncomeField( 
                  controller: exemptCtrl, 
                  label: "Exempt Income Amount", 
                  keyboardType: TextInputType.number,
                ), 
              ),
              const SizedBox(height: 40), 
              Center( 
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon( 
                    onPressed: saveExemptIncome, 
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    label: const Text("Save & Return", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)
                      )
                    ),
                  ),
                ), 
              ), 
            ], 
          ), 
        ),
      ), 
    ); 
  } 
}
