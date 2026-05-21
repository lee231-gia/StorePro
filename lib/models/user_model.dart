// Represents the store owner's profile.
// Stored in Firestore: stores/{storeId}
// Also cached locally in SharedPreferences (simple key-value).

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String storeName;
  final String avatarColorIndex;
  final String securityQuestion;
  final String securityAnswerHash; // hashed answer
  final String otpCode; // current active OTP
  final String otpExpiresAt; // ISO datetime string
  final bool trackActivity;
  final bool notificationsEnabled;
  final bool employeeFeature;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.storeName,
    this.avatarColorIndex = '0',
    this.securityQuestion = '',
    this.securityAnswerHash = '',
    this.otpCode = '',
    this.otpExpiresAt = '',
    this.trackActivity = true,
    this.notificationsEnabled = true,
    this.employeeFeature = true,
    required this.createdAt,
  });

  // ── FROM FIRESTORE MAP ────────────────────────────────────
  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    id: m['id'] ?? '',
    email: m['email'] ?? '',
    firstName: m['firstName'] ?? '',
    lastName: m['lastName'] ?? '',
    username: m['username'] ?? '',
    storeName: m['storeName'] ?? '',
    avatarColorIndex: m['avatarColorIndex'] ?? '0',
    securityQuestion: m['securityQuestion'] ?? '',
    securityAnswerHash: m['securityAnswerHash'] ?? '',
    otpCode: m['otpCode'] ?? '',
    otpExpiresAt: m['otpExpiresAt'] ?? '',
    trackActivity: m['trackActivity'] ?? true,
    notificationsEnabled: m['notificationsEnabled'] ?? true,
    employeeFeature: m['employeeFeature'] ?? true,
    createdAt: m['createdAt'] ?? '',
  );

  // ── TO FIRESTORE MAP ──────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'username': username,
    'storeName': storeName,
    'avatarColorIndex': avatarColorIndex,
    'securityQuestion': securityQuestion,
    'securityAnswerHash': securityAnswerHash,
    'otpCode': otpCode,
    'otpExpiresAt': otpExpiresAt,
    'trackActivity': trackActivity,
    'notificationsEnabled': notificationsEnabled,
    'employeeFeature': employeeFeature,
    'createdAt': createdAt,
  };

  // ── COPY WITH ─────────────────────────────────────────────
  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? storeName,
    String? avatarColorIndex,
    String? securityQuestion,
    String? securityAnswerHash,
    String? otpCode,
    String? otpExpiresAt,
    bool? trackActivity,
    bool? notificationsEnabled,
    bool? employeeFeature,
  }) => UserModel(
    id: id,
    email: email,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    username: username ?? this.username,
    storeName: storeName ?? this.storeName,
    avatarColorIndex: avatarColorIndex ?? this.avatarColorIndex,
    securityQuestion: securityQuestion ?? this.securityQuestion,
    securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
    otpCode: otpCode ?? this.otpCode,
    otpExpiresAt: otpExpiresAt ?? this.otpExpiresAt,
    trackActivity: trackActivity ?? this.trackActivity,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    employeeFeature: employeeFeature ?? this.employeeFeature,
    createdAt: createdAt,
  );

  String get fullName => '$firstName $lastName'.trim();
}
