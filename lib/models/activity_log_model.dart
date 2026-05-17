// Records every employee action in the system.
// Only saved when Session.trackActivity == true.

class ActivityLogModel {
  final String id;
  final String storeId;
  final String employeeId;
  final String employeeName;
  final String action; // 'add_product' | 'edit_product' | 'new_sale' etc.
  final String targetType; // 'product' | 'sale' | 'category' etc.
  final String targetId;
  final String targetName;
  final String timestamp;

  const ActivityLogModel({
    required this.id,
    required this.storeId,
    required this.employeeId,
    required this.employeeName,
    required this.action,
    required this.targetType,
    this.targetId = '',
    this.targetName = '',
    required this.timestamp,
  });

  factory ActivityLogModel.fromMap(Map<String, dynamic> m) => ActivityLogModel(
    id: m['id'] ?? '',
    storeId: m['storeId'] ?? '',
    employeeId: m['employeeId'] ?? '',
    employeeName: m['employeeName'] ?? '',
    action: m['action'] ?? '',
    targetType: m['targetType'] ?? '',
    targetId: m['targetId'] ?? '',
    targetName: m['targetName'] ?? '',
    timestamp: m['timestamp'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'storeId': storeId,
    'employeeId': employeeId,
    'employeeName': employeeName,
    'action': action,
    'targetType': targetType,
    'targetId': targetId,
    'targetName': targetName,
    'timestamp': timestamp,
  };

  Map<String, dynamic> toSql() => toMap();
}
