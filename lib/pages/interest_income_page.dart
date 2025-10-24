//pages/interest_income_page.dart
import 'package:flutter/material.dart';
import '../services/tax_data_service.dart';
import '../widgets/income_field.dart';
// InterestAccountData is now defined in tax_data_service.dart

class InterestIncomePage extends StatefulWidget {
  const InterestIncomePage({super.key});

  @override
  State<InterestIncomePage> createState() => InterestIncomePageState();
}

class InterestIncomePageState extends State<InterestIncomePage>
    with TickerProviderStateMixin {
  final TaxDataService service = TaxDataService();

  final List<String> months = const [
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
    "January",
    "February",
    "March",
  ];

  // UI state lists: [TextEditingController for interest, String for month, TextEditingController for WHT]
  List<List<dynamic>> fixedDepositAccounts = [];
  List<List<dynamic>> savingAccounts = [];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // --- Animations ---
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
    _slideController.forward();

    // **** MODIFICATION START: Load existing accounts from service data ****
    fixedDepositAccounts = []; // Clear potential default
    if (service.fixedDepositAccountDetails.isNotEmpty) {
      for (var savedAcc in service.fixedDepositAccountDetails) {
        // Ensure month is valid, otherwise default
        String validMonth =
            months.contains(savedAcc.month) ? savedAcc.month : months[0];
        fixedDepositAccounts.add([
          TextEditingController(
              text: savedAcc.interest > 0
                  ? savedAcc.interest.toStringAsFixed(2)
                  : ''),
          validMonth, // Use the potentially corrected month
          TextEditingController(
              text: savedAcc.wht > 0 ? savedAcc.wht.toStringAsFixed(2) : ''),
        ]);
      }
    } else {
      // If no saved data, add one default empty row to UI list
      _addAccountRow(fixedDepositAccounts); // Use helper
    }

    savingAccounts = []; // Clear potential default
    if (service.savingAccountDetails.isNotEmpty) {
      for (var savedAcc in service.savingAccountDetails) {
        // Ensure month is valid, otherwise default
        String validMonth =
            months.contains(savedAcc.month) ? savedAcc.month : months[0];
        savingAccounts.add([
          TextEditingController(
              text: savedAcc.interest > 0
                  ? savedAcc.interest.toStringAsFixed(2)
                  : ''),
          validMonth, // Use the potentially corrected month
          TextEditingController(
              text: savedAcc.wht > 0 ? savedAcc.wht.toStringAsFixed(2) : ''),
        ]);
      }
    } else {
      // If no saved data, add one default empty row to UI list
      _addAccountRow(savingAccounts); // Use helper
    }
    // **** MODIFICATION END ****
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    // Dispose controllers in UI lists
    _disposeAccountControllers(fixedDepositAccounts);
    _disposeAccountControllers(savingAccounts);
    super.dispose();
  }

  // Helper to dispose controllers in a list
  void _disposeAccountControllers(List<List<dynamic>> accounts) {
    for (var acc in accounts) {
      if (acc.length >= 3) {
        if (acc[0] is TextEditingController) acc[0].dispose();
        if (acc[2] is TextEditingController) acc[2].dispose();
      }
    }
  }

  // Helper to add a new row with controllers to the UI list
  void _addAccountRow(List<List<dynamic>> accountList) {
    accountList.add([
      TextEditingController(),
      months[0], // Default month
      TextEditingController(),
    ]);
  }

  void addFixedDepositAccount() {
    setState(() {
      _addAccountRow(fixedDepositAccounts);
    });
  }

  void addSavingAccount() {
    setState(() {
      _addAccountRow(savingAccounts);
    });
  }

  // **** MODIFICATION: Update save logic ****
  void saveInterestIncome() async {
    // Add async
    double overallTotalInterest = 0.0; // Combined total for message
    double fdTotalInterest = 0.0;
    double savingsTotalInterest = 0.0;

    // Clear the detail lists in the service before adding current data
    service.fixedDepositAccountDetails.clear();
    service.savingAccountDetails.clear();

    // Ensure monthly lists have 12 elements
    if (service.monthlyInvestmentTotals.length < 12)
      service.monthlyInvestmentTotals.addAll(
          List.filled(12 - service.monthlyInvestmentTotals.length, 0.0));
    if (service.monthlyInvestmentCategories.length < 12)
      service.monthlyInvestmentCategories.addAll(List.generate(
          12 - service.monthlyInvestmentCategories.length, (_) => {}));

    // Reset specific monthly totals and categories related to interest
    List<double> fdMonthlyAccumulator = List.filled(12, 0.0);
    List<double> savingsMonthlyAccumulator = List.filled(12, 0.0);

    for (int i = 0; i < 12; i++) {
      // Ensure the map for the month exists
      if (service.monthlyInvestmentCategories[i] == null)
        service.monthlyInvestmentCategories[i] = {};

      // Calculate previous interest contribution for this month to subtract it later
      // Use null-aware operators ?? 0.0
      double previousFDInterest = service.monthlyInvestmentCategories[i]
                  ['Fixed Deposit Interest']
              ?.fold<double>(0.0, (double s, double? v) => s + (v ?? 0.0)) ??
          0.0;
      double previousSavingInterest = service.monthlyInvestmentCategories[i]
                  ['Normal Saving Interest']
              ?.fold<double>(0.0, (double s, double? v) => s + (v ?? 0.0)) ??
          0.0;

      // Ensure the total for the month is not null before subtracting
      double currentMonthTotal = service.monthlyInvestmentTotals[i] ?? 0.0;
      currentMonthTotal -= (previousFDInterest + previousSavingInterest);
      service.monthlyInvestmentTotals[i] =
          (currentMonthTotal < 0.0) ? 0.0 : currentMonthTotal; // Floor at zero

      // Reset the detailed lists for these categories for this month
      service.monthlyInvestmentCategories[i]['Fixed Deposit Interest'] = [0.0];
      service.monthlyInvestmentCategories[i]['Normal Saving Interest'] = [0.0];
    }

    // Process Fixed Deposit Accounts from UI
    for (var acc in fixedDepositAccounts) {
      if (acc.length >= 3 &&
          acc[0] is TextEditingController &&
          acc[1] is String &&
          acc[2] is TextEditingController) {
        double interest =
            double.tryParse((acc[0] as TextEditingController).text) ?? 0.0;
        String month = acc[1] as String;
        double wht =
            double.tryParse((acc[2] as TextEditingController).text) ?? 0.0;

        // Save details to service list only if there's actual data
        if (interest > 0 || wht > 0) {
          service.fixedDepositAccountDetails.add(
              InterestAccountData(interest: interest, month: month, wht: wht));
        }

        fdTotalInterest += interest; // Accumulate annual total
        overallTotalInterest += interest;

        // Accumulate for monthly totals update
        int monthIndex = months.indexOf(month);
        if (monthIndex >= 0 && monthIndex < 12) {
          fdMonthlyAccumulator[monthIndex] += interest;
        }
      }
    }
    // Update the annual category total
    service.investmentCategories["Fixed Deposit Interest"] = fdTotalInterest;

    // Process Saving Accounts from UI
    for (var acc in savingAccounts) {
      if (acc.length >= 3 &&
          acc[0] is TextEditingController &&
          acc[1] is String &&
          acc[2] is TextEditingController) {
        double interest =
            double.tryParse((acc[0] as TextEditingController).text) ?? 0.0;
        String month = acc[1] as String;
        double wht =
            double.tryParse((acc[2] as TextEditingController).text) ?? 0.0;

        // Save details to service list only if there's actual data
        if (interest > 0 || wht > 0) {
          service.savingAccountDetails.add(
              InterestAccountData(interest: interest, month: month, wht: wht));
        }

        savingsTotalInterest += interest; // Accumulate annual total
        overallTotalInterest += interest;

        // Accumulate for monthly totals update
        int monthIndex = months.indexOf(month);
        if (monthIndex >= 0 && monthIndex < 12) {
          savingsMonthlyAccumulator[monthIndex] += interest;
        }
      }
    }
    // Update the annual category total
    service.investmentCategories["Normal Saving Interest"] =
        savingsTotalInterest;

    // Update detailed monthly categories and overall monthly investment totals
    for (int i = 0; i < 12; i++) {
      if (service.monthlyInvestmentCategories[i] == null)
        service.monthlyInvestmentCategories[i] = {};
      // Set the detailed list for the month based on accumulated values (use [0.0] if zero)
      service.monthlyInvestmentCategories[i]['Fixed Deposit Interest'] =
          fdMonthlyAccumulator[i] > 0 ? [fdMonthlyAccumulator[i]] : [0.0];
      service.monthlyInvestmentCategories[i]['Normal Saving Interest'] =
          savingsMonthlyAccumulator[i] > 0
              ? [savingsMonthlyAccumulator[i]]
              : [0.0];

      // **** SAFER ADDITION HERE ****
      // Ensure the current total is not null before adding
      double currentTotal = service.monthlyInvestmentTotals[i] ?? 0.0;
      service.monthlyInvestmentTotals[i] = currentTotal +
          (fdMonthlyAccumulator[i] + savingsMonthlyAccumulator[i]);
      // **** END SAFER ADDITION ****
    }

    // Recalculate overall annual investment total from the category map
    service.calculateTotalInvestmentIncome();

    // Save the entire service state to the database
    await service.saveDataForCurrentUserAndYear();

    // Show confirmation and navigate back
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                  "Interest income saved: Rs. ${overallTotalInterest.toStringAsFixed(2)}"),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    }
  }
  // **** END OF MODIFICATION ****

  // buildAccountSection remains the same as previous version, using the UI state lists
  Widget buildAccountSection(
    String title,
    List<List<dynamic>> accounts, // This is the UI state list
    VoidCallback onAdd,
  ) {
    // ... (Keep the exact code from the previous response for this function) ...
    const primaryColor = Color(0xFF38E07B);
    const primaryDark = Color(0xFF2DD96A);
    const accentGreen = Color(0xFF10B981);
    const neutral900 = Color(0xFF111714);
    const neutral300 = Color(0xFFdce5df);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  title.contains("Fixed Deposit")
                      ? Icons.savings
                      : Icons.account_balance,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: neutral900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              // Ensure account data structure is valid before accessing
              if (accounts.length <= index ||
                  accounts[index].length < 3 ||
                  accounts[index][0] == null ||
                  accounts[index][1] == null ||
                  accounts[index][2] == null) {
                print(
                    "Error: Invalid account structure at index $index for $title");
                return Container(); // Skip rendering invalid row
              }
              // Safely cast controllers and month string
              final interestCtrl = accounts[index][0] as TextEditingController?;
              final selectedMonth =
                  accounts[index][1] as String?; // It's already a String
              final whtCtrl = accounts[index][2] as TextEditingController?;

              if (interestCtrl == null ||
                  whtCtrl == null ||
                  selectedMonth == null) {
                print(
                    "Error: Null controller or month at index $index for $title");
                return Container(); // Skip rendering this item
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.05),
                      accentGreen.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Account ${index + 1}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (accounts.length > 1)
                          GestureDetector(
                            onTap: () => setState(() {
                              // Safely dispose controllers before removing
                              if (accounts[index][0] is TextEditingController)
                                accounts[index][0].dispose();
                              if (accounts[index][2] is TextEditingController)
                                accounts[index][2].dispose();
                              accounts.removeAt(index);
                            }),
                            child: const Icon(Icons.remove_circle,
                                color: Colors.red, size: 24),
                          )
                      ],
                    ),
                    const SizedBox(height: 16),
                    IncomeField(
                      controller: interestCtrl, // Use safe controller
                      label: "$title ${index + 1} - Interest Income (Gross)",
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: neutral300),
                      ),
                      child: Row(
                        children: [
                          const Flexible(
                            child: Text(
                              "Month income received?",
                              style: TextStyle(
                                color: neutral900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: DropdownButton<String>(
                              value: months.contains(selectedMonth)
                                  ? selectedMonth
                                  : months[
                                      0], // Use safe value, default if invalid
                              underline: const SizedBox(),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                color: neutral900,
                                fontWeight: FontWeight.w500,
                              ),
                              items: months
                                  .map(
                                    (val) => DropdownMenuItem(
                                      value: val,
                                      child: Text(val),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => setState(() {
                                // Update the string value directly in the UI state list
                                accounts[index][1] = val ?? months[0];
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IncomeField(
                      controller: whtCtrl, // Use safe controller
                      label: "$title ${index + 1} - WHT Amount",
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: Text("Add Another $title Account",
                  style: const TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: primaryColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                  if (states.contains(WidgetState.pressed)) return primaryDark;
                  return primaryColor;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (Keep existing build method as is) ...
    const primaryColor = Color(0xFF38E07B);
    const primaryLight = Color(0xFF5FE896);
    const neutral50 = Color(0xFFf8faf9);
    const neutral900 = Color(0xFF111714);
    const accentGreen = Color(0xFF10B981);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              neutral50,
              primaryColor.withOpacity(0.05),
              primaryLight.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Custom App Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Interest Income",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: neutral900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "Enter your interest income details",
                              style: TextStyle(
                                fontSize: 14,
                                color: accentGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Header Section
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryColor, accentGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Interest Income Details",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Add your fixed deposit and savings account interest income",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Content
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          buildAccountSection(
                            "Fixed Deposit",
                            fixedDepositAccounts, // UI state list
                            addFixedDepositAccount,
                          ),
                          buildAccountSection(
                            "Normal Saving",
                            savingAccounts, // UI state list
                            addSavingAccount,
                          ),
                          const SizedBox(
                              height: 100), // Space for floating button
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: saveInterestIncome, // Calls modified function
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        label: const Text(
          "Save Interest Income",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.save_rounded),
      ),
    );
  }
}
