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
  static bool notificationsEnabled = true;
  static bool employeeFeature = false;
  static bool isOnline = true;
  static bool employeeSelected = false;

  static String get safeEmployeeId =>
      activeEmployeeId.trim().isNotEmpty ? activeEmployeeId : 'owner';

  static String get safeEmployeeName {
    if (activeEmployeeName.trim().isNotEmpty) return activeEmployeeName.trim();
    if (ownerName.trim().isNotEmpty) return ownerName.trim();
    return 'Owner';
  }

  static void clear() {
    storeId = '';
    storeName = '';
    ownerName = '';
    ownerUsername = '';
    ownerEmail = '';
    activeEmployeeId = '';
    activeEmployeeName = '';
    trackActivity = true;
    notificationsEnabled = true;
    employeeFeature = false;
    employeeSelected = false;
    isOnline = true;
  }
}
