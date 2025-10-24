//services/tax_data_service.dart
import 'dart:convert';
import 'database_helper.dart';

// Helper class for Interest Account data
class InterestAccountData {
  double interest;
  String month;
  double wht;

  InterestAccountData(
      {this.interest = 0.0, this.month = "April", this.wht = 0.0});

  Map<String, dynamic> toJson() => {
        'interest': interest,
        'month': month,
        'wht': wht,
      };

  factory InterestAccountData.fromJson(Map<String, dynamic> json) =>
      InterestAccountData(
        interest: (json['interest'] ?? 0.0).toDouble(),
        month: json['month'] ?? "April", // Default to April if month is missing
        wht: (json['wht'] ?? 0.0).toDouble(),
      );

  // Helper to check if data is default/empty
  bool get isDefaultOrEmpty =>
      interest == 0.0 && wht == 0.0; // Month defaults anyway
}

// Singleton class to manage application-wide state locally
class TaxDataService {
  static final TaxDataService _instance = TaxDataService._internal();
  factory TaxDataService() => _instance;
  TaxDataService._internal() {
    resetToDefaults();
  }

  // User and Year tracking
  int? currentUserId;
  String selectedTaxYear = "2024/2025";

  // --- Data Fields ---
  // ... (keep other fields like monthly totals, other income types, etc.) ...
  List<double> monthlyEmploymentTotals = List.filled(12, 0.0);
  List<double> monthlyBusinessTotals = List.filled(12, 0.0);
  List<double> monthlyInvestmentTotals =
      List.filled(12, 0.0); // Keep overall monthly investment total
  List<double> monthlyForeignTotals = List.filled(12, 0.0);
  List<double> monthlyOtherTotals = List.filled(12, 0.0);
  double charity = 0.0,
      govDonations = 0.0,
      presidentsFund = 0.0,
      femaleShop = 0.0,
      filmExpenditure = 0.0,
      cinemaNew = 0.0,
      cinemaUpgrade = 0.0,
      exemptIncome = 0.0,
      foreignTaxCredits = 0.0;
  double totalEmploymentIncome = 0.0,
      totalBusinessIncome = 0.0,
      totalInvestmentIncome = 0.0,
      totalRentIncome = 0.0,
      rentBusinessIncome = 0.0,
      rentBusinessWht = 0.0,
      totalSolarIncome = 0.0,
      totalOtherIncome = 0.0,
      totalForeignIncome = 0.0;
  Map<String, double> employmentCategories = {};
  List<Map<String, double>> monthlyEmploymentCategories = [];
  Map<String, double> businessCategories = {};
  List<Map<String, double>> monthlyBusinessCategories = [];
  String businessInputMode = "Annual";
  List<double> monthlyRentBusinessIncome = List.filled(12, 0.0);
  List<double> monthlyRentBusinessWht = List.filled(12, 0.0);
  List<String> monthlyRentMaintainedByUser = List.filled(12, "No");
  Map<String, double> investmentCategories = {};
  List<Map<String, List<double>>> monthlyInvestmentCategories = [];
  Map<String, String> investmentInputMode = {};
  Map<String, double> foreignIncomeCategories = {};
  List<Map<String, List<double>>> monthlyForeignCategories = [];
  Map<String, String> foreignInputMode = {};
  List<List<double>> monthlyOtherCategories = List.generate(12, (_) => [0.0]);
  String otherInputMode = "Annual";
  double apitAmount = 0.0;
  List<double> monthlyApitAmounts = List.filled(12, 0.0);
  bool rentMaintainedByUser = false;
  double solarInstallCost = 0.0;
  int solarReliefCount = 0;
  double rentRelief = 0.0, solarPanel = 0.0;
  bool? isMaintainedByUser = false;

  // *** MODIFICATION: Store Interest Account Details ***
  List<InterestAccountData> fixedDepositAccountDetails = [];
  List<InterestAccountData> savingAccountDetails = [];
  // *** END MODIFICATION ***

  // --- JSON Serialization & Deserialization ---
  Map<String, dynamic> toJson() {
    return {
      // ... (keep all other existing fields) ...
      'totalEmploymentIncome': totalEmploymentIncome,
      'apitAmount': apitAmount,
      'employmentCategories': employmentCategories,
      'monthlyEmploymentCategories': monthlyEmploymentCategories,
      'monthlyApitAmounts': monthlyApitAmounts,
      'monthlyEmploymentTotals': monthlyEmploymentTotals,
      'monthlyBusinessTotals': monthlyBusinessTotals,
      'monthlyInvestmentTotals': monthlyInvestmentTotals,
      'monthlyForeignTotals': monthlyForeignTotals,
      'monthlyOtherTotals': monthlyOtherTotals,
      'charity': charity,
      'govDonations': govDonations,
      'presidentsFund': presidentsFund,
      'femaleShop': femaleShop,
      'filmExpenditure': filmExpenditure,
      'cinemaNew': cinemaNew,
      'cinemaUpgrade': cinemaUpgrade,
      'exemptIncome': exemptIncome,
      'foreignTaxCredits': foreignTaxCredits,
      'totalBusinessIncome': totalBusinessIncome,
      'totalInvestmentIncome': totalInvestmentIncome,
      'totalRentIncome': totalRentIncome,
      'rentBusinessIncome': rentBusinessIncome,
      'rentBusinessWht': rentBusinessWht,
      'totalSolarIncome': totalSolarIncome,
      'totalOtherIncome': totalOtherIncome,
      'totalForeignIncome': totalForeignIncome,
      'monthlyRentBusinessIncome': monthlyRentBusinessIncome,
      'monthlyRentBusinessWht': monthlyRentBusinessWht,
      'monthlyRentMaintainedByUser': monthlyRentMaintainedByUser,
      'investmentCategories': investmentCategories,
      'monthlyInvestmentCategories': monthlyInvestmentCategories,
      'foreignIncomeCategories': foreignIncomeCategories,
      'monthlyForeignCategories': monthlyForeignCategories,
      'monthlyOtherCategories': monthlyOtherCategories,
      'rentMaintainedByUser': rentMaintainedByUser,
      'solarInstallCost': solarInstallCost,
      'solarReliefCount': solarReliefCount,
      'rentRelief': rentRelief,
      'solarPanel': solarPanel,
      'isMaintainedByUser': isMaintainedByUser,
      'businessCategories': businessCategories,
      'monthlyBusinessCategories': monthlyBusinessCategories,
      'businessInputMode': businessInputMode,
      'investmentInputMode': investmentInputMode,
      'foreignInputMode': foreignInputMode,
      'otherInputMode': otherInputMode,

      // *** MODIFICATION: Add Interest Account Lists to JSON ***
      'fixedDepositAccountDetails':
          fixedDepositAccountDetails.map((acc) => acc.toJson()).toList(),
      'savingAccountDetails':
          savingAccountDetails.map((acc) => acc.toJson()).toList(),
      // *** END MODIFICATION ***
    };
  }

  void fromJson(Map<String, dynamic> json) {
    try {
      // ... (keep loading for all other existing fields - ensure safety checks are present as added previously) ...
      totalEmploymentIncome = (json['totalEmploymentIncome'] ?? 0.0).toDouble();
      apitAmount = (json['apitAmount'] ?? 0.0).toDouble();
      employmentCategories =
          Map<String, double>.from(json['employmentCategories'] ?? {});
      var loadedMonthlyEmpCats = json['monthlyEmploymentCategories'] as List?;
      if (loadedMonthlyEmpCats != null) {
        monthlyEmploymentCategories = loadedMonthlyEmpCats
            .map((e) => Map<String, double>.from(e ?? {}))
            .toList();
        if (monthlyEmploymentCategories.length < 12) {
          monthlyEmploymentCategories.addAll(List.generate(
              12 - monthlyEmploymentCategories.length, (_) => {}));
        }
      } else {
        monthlyEmploymentCategories = List.generate(12, (_) => {});
      }
      var loadedApit = json['monthlyApitAmounts'] as List?;
      monthlyApitAmounts = loadedApit
              ?.map<double>((e) => (e as num? ?? 0.0).toDouble())
              .toList() ??
          List.filled(12, 0.0);
      if (monthlyApitAmounts.length < 12)
        monthlyApitAmounts
            .addAll(List.filled(12 - monthlyApitAmounts.length, 0.0));
      var loadedEmpTotals = json['monthlyEmploymentTotals'] as List?;
      monthlyEmploymentTotals = loadedEmpTotals
              ?.map<double>((e) => (e as num? ?? 0.0).toDouble())
              .toList() ??
          List.filled(12, 0.0);
      if (monthlyEmploymentTotals.length < 12)
        monthlyEmploymentTotals
            .addAll(List.filled(12 - monthlyEmploymentTotals.length, 0.0));
      var loadedBusTotals = json['monthlyBusinessTotals'] as List?;
      monthlyBusinessTotals = loadedBusTotals
              ?.map<double>((e) => (e as num? ?? 0.0).toDouble())
              .toList() ??
          List.filled(12, 0.0);
      if (monthlyBusinessTotals.length < 12)
        monthlyBusinessTotals
            .addAll(List.filled(12 - monthlyBusinessTotals.length, 0.0));
      var loadedInvTotals = json['monthlyInvestmentTotals'] as List?;
      monthlyInvestmentTotals = loadedInvTotals
              ?.map<double>((e) => (e as num? ?? 0.0).toDouble())
              .toList() ??
          List.filled(12, 0.0);
      if (monthlyInvestmentTotals.length < 12)
        monthlyInvestmentTotals
            .addAll(List.filled(12 - monthlyInvestmentTotals.length, 0.0));
      var loadedForTotals = json['monthlyForeignTotals'] as List?;
      monthlyForeignTotals = loadedForTotals
              ?.map<double>((e) => (e as num? ?? 0.0).toDouble())
              .toList() ??
          List.filled(12, 0.0);
      if (monthlyForeignTotals.length < 12)
        monthlyForeignTotals
            .addAll(List.filled(12 - monthlyForeignTotals.length, 0.0));
      var loadedOthTotals = json['monthlyOtherTotals'] as List?;
      monthlyOtherTotals = loadedOthTotals
              ?.map<double>((e) => (e as num? ?? 0.0).toDouble())
              .toList() ??
          List.filled(12, 0.0);
      if (monthlyOtherTotals.length < 12)
        monthlyOtherTotals
            .addAll(List.filled(12 - monthlyOtherTotals.length, 0.0));
      charity = (json['charity'] ?? 0.0).toDouble();
      govDonations = (json['govDonations'] ?? 0.0).toDouble();
      presidentsFund = (json['presidentsFund'] ?? 0.0).toDouble();
      femaleShop = (json['femaleShop'] ?? 0.0).toDouble();
      filmExpenditure = (json['filmExpenditure'] ?? 0.0).toDouble();
      cinemaNew = (json['cinemaNew'] ?? 0.0).toDouble();
      cinemaUpgrade = (json['cinemaUpgrade'] ?? 0.0).toDouble();
      exemptIncome = (json['exemptIncome'] ?? 0.0).toDouble();
      foreignTaxCredits = (json['foreignTaxCredits'] ?? 0.0).toDouble();
      totalBusinessIncome = (json['totalBusinessIncome'] ?? 0.0).toDouble();
      totalInvestmentIncome = (json['totalInvestmentIncome'] ?? 0.0).toDouble();
      totalRentIncome = (json['totalRentIncome'] ?? 0.0).toDouble();
      rentBusinessIncome = (json['rentBusinessIncome'] ?? 0.0).toDouble();
      rentBusinessWht = (json['rentBusinessWht'] ?? 0.0).toDouble();
      totalSolarIncome = (json['totalSolarIncome'] ?? 0.0).toDouble();
      totalOtherIncome = (json['totalOtherIncome'] ?? 0.0).toDouble();
      totalForeignIncome = (json['totalForeignIncome'] ?? 0.0).toDouble();
      var loadedMonthlyRentIncome = json['monthlyRentBusinessIncome'] as List?;
      monthlyRentBusinessIncome = loadedMonthlyRentIncome
              ?.map<double>((e) => (e as num? ?? 0.0).toDouble())
              .toList() ??
          List.filled(12, 0.0);
      if (monthlyRentBusinessIncome.length < 12)
        monthlyRentBusinessIncome
            .addAll(List.filled(12 - monthlyRentBusinessIncome.length, 0.0));
      var loadedMonthlyRentWht = json['monthlyRentBusinessWht'] as List?;
      monthlyRentBusinessWht = loadedMonthlyRentWht
              ?.map<double>((e) => (e as num? ?? 0.0).toDouble())
              .toList() ??
          List.filled(12, 0.0);
      if (monthlyRentBusinessWht.length < 12)
        monthlyRentBusinessWht
            .addAll(List.filled(12 - monthlyRentBusinessWht.length, 0.0));
      var loadedMonthlyRentMaintained =
          json['monthlyRentMaintainedByUser'] as List?;
      monthlyRentMaintainedByUser = loadedMonthlyRentMaintained
              ?.map<String>((e) => e?.toString() ?? "No")
              .toList() ??
          List.filled(12, "No");
      if (monthlyRentMaintainedByUser.length < 12)
        monthlyRentMaintainedByUser
            .addAll(List.filled(12 - monthlyRentMaintainedByUser.length, "No"));
      investmentCategories =
          Map<String, double>.from(json['investmentCategories'] ?? {});
      var loadedMonthlyInvCats = json['monthlyInvestmentCategories'] as List?;
      if (loadedMonthlyInvCats != null) {
        monthlyInvestmentCategories = loadedMonthlyInvCats.map((monthlyMap) {
          var typedMap = Map<String, dynamic>.from(monthlyMap ?? {});
          return typedMap.map((key, value) {
            var valueListRaw = value as List?;
            var valueList = valueListRaw
                    ?.map<double>((e) => (e as num? ?? 0.0).toDouble())
                    .toList() ??
                [0.0];
            return MapEntry(key, valueList);
          });
        }).toList();
        if (monthlyInvestmentCategories.length < 12) {
          monthlyInvestmentCategories.addAll(List.generate(
              12 - monthlyInvestmentCategories.length, (_) => {}));
        }
      } else {
        monthlyInvestmentCategories = List.generate(12, (_) => {});
      }
      foreignIncomeCategories =
          Map<String, double>.from(json['foreignIncomeCategories'] ?? {});
      var loadedMonthlyForCats = json['monthlyForeignCategories'] as List?;
      if (loadedMonthlyForCats != null) {
        monthlyForeignCategories = loadedMonthlyForCats.map((monthlyMap) {
          var typedMap = Map<String, dynamic>.from(monthlyMap ?? {});
          return typedMap.map((key, value) {
            var valueListRaw = value as List?;
            var valueList = valueListRaw
                    ?.map<double>((e) => (e as num? ?? 0.0).toDouble())
                    .toList() ??
                [0.0];
            return MapEntry(key, valueList);
          });
        }).toList();
        if (monthlyForeignCategories.length < 12) {
          monthlyForeignCategories.addAll(
              List.generate(12 - monthlyForeignCategories.length, (_) => {}));
        }
      } else {
        monthlyForeignCategories = List.generate(12, (_) => {});
      }
      var loadedMonthlyOthCats = json['monthlyOtherCategories'] as List?;
      if (loadedMonthlyOthCats != null) {
        monthlyOtherCategories = loadedMonthlyOthCats.map((innerList) {
          var innerListRaw = innerList as List?;
          return innerListRaw
                  ?.map<double>((e) => (e as num? ?? 0.0).toDouble())
                  .toList() ??
              [0.0];
        }).toList();
        if (monthlyOtherCategories.length < 12) {
          monthlyOtherCategories.addAll(
              List.generate(12 - monthlyOtherCategories.length, (_) => [0.0]));
        }
      } else {
        monthlyOtherCategories = List.generate(12, (_) => [0.0]);
      }
      rentMaintainedByUser = json['rentMaintainedByUser'] ?? false;
      solarInstallCost = (json['solarInstallCost'] ?? 0.0).toDouble();
      solarReliefCount = (json['solarReliefCount'] ?? 0).toInt();
      rentRelief = (json['rentRelief'] ?? 0.0).toDouble();
      solarPanel = (json['solarPanel'] ?? 0.0).toDouble();
      isMaintainedByUser = json['isMaintainedByUser'] ?? false;
      businessCategories =
          Map<String, double>.from(json['businessCategories'] ?? {});
      var loadedMonthlyBusCats = json['monthlyBusinessCategories'] as List?;
      if (loadedMonthlyBusCats != null) {
        monthlyBusinessCategories = loadedMonthlyBusCats
            .map((e) => Map<String, double>.from(e ?? {}))
            .toList();
        if (monthlyBusinessCategories.length < 12) {
          monthlyBusinessCategories.addAll(
              List.generate(12 - monthlyBusinessCategories.length, (_) => {}));
        }
      } else {
        monthlyBusinessCategories = List.generate(12, (_) => {});
      }
      businessInputMode = json['businessInputMode'] ?? "Annual";
      investmentInputMode =
          Map<String, String>.from(json['investmentInputMode'] ?? {});
      foreignInputMode =
          Map<String, String>.from(json['foreignInputMode'] ?? {});
      otherInputMode = json['otherInputMode'] ?? "Annual";

      // *** MODIFICATION START: Load Interest Account Lists from JSON ***
      var loadedFixedDeposits = json['fixedDepositAccountDetails'] as List?;
      if (loadedFixedDeposits != null) {
        fixedDepositAccountDetails = loadedFixedDeposits
            .map((data) {
              // Add null check for data
              if (data == null)
                return InterestAccountData(); // Return default if data is null
              return InterestAccountData.fromJson(
                  Map<String, dynamic>.from(data));
            })
            .where((item) =>
                item !=
                null) // Filter out potential nulls if any error occurred
            .toList();
      } else {
        fixedDepositAccountDetails = []; // Initialize empty if null
      }

      var loadedSavings = json['savingAccountDetails'] as List?;
      if (loadedSavings != null) {
        savingAccountDetails = loadedSavings
            .map((data) {
              // Add null check for data
              if (data == null)
                return InterestAccountData(); // Return default if data is null
              return InterestAccountData.fromJson(
                  Map<String, dynamic>.from(data));
            })
            .where((item) => item != null) // Filter out potential nulls
            .toList();
      } else {
        savingAccountDetails = []; // Initialize empty if null
      }
      // *** MODIFICATION END ***
    } catch (e) {
      print("Error during fromJson: $e");
      resetToDefaults();
    }
  }

  // --- Database Interaction ---
  // ... (keep loadDataForCurrentUserAndYear and saveDataForCurrentUserAndYear as is) ...
  Future<void> loadDataForCurrentUserAndYear() async {
    if (currentUserId == null) {
      print("Cannot load data: No user ID set.");
      resetToDefaults();
      return;
    }
    print("Loading data for user $currentUserId and year $selectedTaxYear");
    String? jsonData = await DatabaseHelper.instance
        .loadTaxData(currentUserId!, selectedTaxYear);
    if (jsonData != null && jsonData.isNotEmpty) {
      try {
        fromJson(jsonDecode(jsonData));
        print("Data loaded successfully.");
      } catch (e) {
        print("Error decoding JSON from DB: $e");
        resetToDefaults();
      }
    } else {
      print("No data found in DB, resetting to defaults.");
      resetToDefaults();
    }
  }

  Future<void> saveDataForCurrentUserAndYear() async {
    if (currentUserId == null) {
      print('Error saving data: No user ID set');
      return;
    }
    try {
      String jsonData = jsonEncode(toJson());
      print(
          "Saving data for user $currentUserId and year $selectedTaxYear: $jsonData");
      await DatabaseHelper.instance
          .saveTaxData(currentUserId!, selectedTaxYear, jsonData);
      print("Data saved successfully to DB.");
    } catch (e) {
      print("Error encoding JSON or saving to DB: $e");
    }
  }

  // --- Calculation & Reset Methods ---
  double calculateTotalInvestmentIncome() {
    // Recalculate from detail map, including the saved totals for interest
    // Ensure all expected keys exist before summing
    double sum = 0;
    _defaultInvestmentCats.forEach((key) {
      sum += investmentCategories[key] ?? 0.0;
    });
    totalInvestmentIncome = sum;
    //totalInvestmentIncome = investmentCategories.values.fold(0.0, (sum, val) => sum + val); // Original might fail if map incomplete
    return totalInvestmentIncome;
  }

  double calculateTotalForeignIncome() {
    // Ensure all expected keys exist before summing
    double sum = 0;
    _defaultForeignCats.forEach((key) {
      sum += foreignIncomeCategories[key] ?? 0.0;
    });
    totalForeignIncome = sum;
    //totalForeignIncome = foreignIncomeCategories.values.fold(0.0, (sum, val) => sum + val); // Original
    return totalForeignIncome;
  }

  // ... (keep default category lists) ...
  final List<String> _defaultBusinessCats = const [
    "Service Fees",
    "Sales of Trading Stock",
    "Capital Gains from Assets/Liabilities",
    "Realisation of Depreciable Assets",
    "Payments for Restrictions",
    "Other Business Income",
    "Rent for Business Purpose",
  ];
  final List<String> _defaultEmploymentCats = const [
    "Salary / Wages",
    "Allowances",
    "Expense Reimbursements",
    "Agreement Payments",
    "Termination Payments",
    "Retirement Contributions & Payments",
    "Payments on Your Behalf",
    "Benefits in Kind",
    "Employee Share Schemes",
  ];
  final List<String> _defaultInvestmentCats = const [
    "Dividends",
    "Discounts, Charges, Annuities",
    "Natural Resource Payments",
    "Premiums",
    "Royalties",
    "Gains from Selling Investment Assets",
    "Payments for Restricting Investment Activity",
    "Lottery, Betting, Gambling Winnings",
    "Other Investment",
    "Residential Rental Income",
    "Solar Income",
    "Fixed Deposit Interest",
    "Normal Saving Interest",
  ];
  final List<String> _defaultForeignCats = const [
    "Foreign Employment",
    "Foreign Business",
    "Foreign Investment",
    "Foreign Other",
  ];

  void resetToDefaults() {
    print("Resetting TaxDataService to defaults.");
    // ... (keep resets for all other fields) ...
    monthlyEmploymentTotals = List.filled(12, 0.0);
    monthlyBusinessTotals = List.filled(12, 0.0);
    monthlyInvestmentTotals = List.filled(12, 0.0);
    monthlyForeignTotals = List.filled(12, 0.0);
    monthlyOtherTotals = List.filled(12, 0.0);
    charity = 0.0;
    govDonations = 0.0;
    presidentsFund = 0.0;
    femaleShop = 0.0;
    filmExpenditure = 0.0;
    cinemaNew = 0.0;
    cinemaUpgrade = 0.0;
    exemptIncome = 0.0;
    foreignTaxCredits = 0.0;
    totalEmploymentIncome = 0.0;
    totalBusinessIncome = 0.0;
    totalInvestmentIncome = 0.0;
    totalRentIncome = 0.0;
    rentBusinessIncome = 0.0;
    rentBusinessWht = 0.0;
    totalSolarIncome = 0.0;
    totalOtherIncome = 0.0;
    totalForeignIncome = 0.0;
    employmentCategories = {for (var cat in _defaultEmploymentCats) cat: 0.0};
    monthlyEmploymentCategories =
        List.generate(12, (_) => Map.from(employmentCategories));
    businessCategories = {for (var cat in _defaultBusinessCats) cat: 0.0};
    monthlyBusinessCategories =
        List.generate(12, (_) => Map.from(businessCategories));
    businessInputMode = "Annual";
    monthlyRentBusinessIncome = List.filled(12, 0.0);
    monthlyRentBusinessWht = List.filled(12, 0.0);
    monthlyRentMaintainedByUser = List.filled(12, "No");
    investmentCategories = {for (var cat in _defaultInvestmentCats) cat: 0.0};
    monthlyInvestmentCategories = List.generate(
        12,
        (_) => {
              for (var cat in _defaultInvestmentCats) cat: [0.0]
            });
    investmentInputMode = {};
    foreignIncomeCategories = {for (var cat in _defaultForeignCats) cat: 0.0};
    monthlyForeignCategories = List.generate(
        12,
        (_) => {
              for (var cat in _defaultForeignCats) cat: [0.0]
            });
    foreignInputMode = {};
    monthlyOtherCategories = List.generate(12, (_) => [0.0]);
    otherInputMode = "Annual";
    apitAmount = 0.0;
    monthlyApitAmounts = List.filled(12, 0.0);
    rentMaintainedByUser = false;
    solarInstallCost = 0.0;
    solarReliefCount = 0;
    rentRelief = 0.0;
    solarPanel = 0.0;
    isMaintainedByUser = false;

    // *** MODIFICATION START: Reset Interest Account Lists ***
    fixedDepositAccountDetails = [];
    savingAccountDetails = [];
    // *** MODIFICATION END ***
  }
}

