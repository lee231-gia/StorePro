import 'package:flutter/material.dart';
import '../core/utils/session.dart';

Future<void> showSessionEmployeePicker(BuildContext context) async {
  _useOwnerForActivityLog();
}

Future<bool> pickEmployee(BuildContext context) async {
  _useOwnerForActivityLog();
  return true;
}

void _useOwnerForActivityLog() {
  Session.activeEmployeeId = 'owner';
  Session.activeEmployeeName = Session.ownerName.isNotEmpty
      ? Session.ownerName
      : 'Admin';
  Session.employeeSelected = true;
}
