//services/income_calculator.dar


class IncomeCalculator { 
  // Employment Income 
  static double calculateUpToNowEmployment(List<double> savedEmploymentIncome, int monthIndex) { 
    double sum = 0.0; 
    for (int i = 0; i <= monthIndex; i++) { 
      sum += savedEmploymentIncome[i]; 
    } 
    return sum; 
  } 
  
  static double calculateAnnualEmployment(List<double> savedEmploymentIncome) { 
    return savedEmploymentIncome.fold(0.0, (sum, val) => sum + val); 
  } 
  
  // Dynamic Income (Business, Investment, Other) 
  static double calculateUpToNowDynamic(List<List<double>> savedDynamicIncome, int monthIndex) { 
    double sum = 0.0; 
    for (int i = 0; i <= monthIndex; i++) { 
      sum += savedDynamicIncome[i].fold(0.0, (s, v) => s + v); 
    } 
    return sum; 
  } 
  
  static double calculateAnnualDynamic(List<List<double>> savedDynamicIncome) { 
    double total = 0.0; 
    for (var month in savedDynamicIncome) { 
      total += month.fold(0.0, (s, v) => s + v); 
    } 
    return total; 
  } 
  
  // Helper to check if all months have at least one value for dynamic income 
  static bool canShowAnnualDynamic(List<List<double>> savedDynamicIncome) { 
    return savedDynamicIncome.every((month) => month.isNotEmpty); 
  } 
}

