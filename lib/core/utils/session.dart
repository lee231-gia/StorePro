class Session {
  Session._();

  static String storeId = '';
  static String storeName = '';
  static String ownerName = '';
  static String ownerUsername = '';
  static String ownerEmail = '';
  static String activeEmployeeId = '';
  static String activeEmployeeName = '';
  static bool trackActivity = true;
  static bool employeeFeature = true; // NEW — toggle in settings
  static bool isOnline = true;
  static bool employeeSelected = false; // NEW — set once at app start

  static void clear() {
    storeId = '';
    storeName = '';
    ownerName = '';
    ownerUsername = '';
    ownerEmail = '';
    activeEmployeeId = '';
    activeEmployeeName = '';
    trackActivity = true;
    employeeFeature = true;
    employeeSelected = false;
    isOnline = true;
  }
}
