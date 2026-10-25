// GET /api/users/me 응답. 로그인 직후 이걸 보고 점주/근로자 화면을 고른다.

enum Role { manager, employee }

enum EmploymentType { partTime, fullTime }

class OwnedStore {
  const OwnedStore({required this.id, required this.name, this.storeCode});

  final int id;
  final String name;
  final String? storeCode;

  factory OwnedStore.fromJson(Map<String, dynamic> j) =>
      OwnedStore(id: j['id'] as int, name: j['name'] as String, storeCode: j['storeCode'] as String?);
}

/// 근로자가 합류 신청한 매장. status: PENDING(승인 대기)·APPROVED·REJECTED
class Membership {
  const Membership({
    required this.employeeId,
    required this.storeId,
    required this.storeName,
    required this.status,
    this.displayName,
    this.employmentType,
  });

  final int employeeId;
  final int storeId;
  final String storeName;
  final String status;
  final String? displayName;
  final EmploymentType? employmentType;

  bool get isApproved => status == 'APPROVED';

  factory Membership.fromJson(Map<String, dynamic> j) => Membership(
        employeeId: j['employeeId'] as int,
        storeId: j['storeId'] as int,
        storeName: j['storeName'] as String,
        status: j['status'] as String,
        displayName: j['displayName'] as String?,
        employmentType: switch (j['employmentType']) {
          'PART_TIME' => EmploymentType.partTime,
          'FULL_TIME' => EmploymentType.fullTime,
          _ => null,
        },
      );
}

class Me {
  const Me({required this.id, required this.username, required this.role, this.ownedStores = const [], this.memberships = const []});

  final int id;
  final String username;
  final Role? role;
  final List<OwnedStore> ownedStores;
  final List<Membership> memberships;

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        id: j['id'] as int,
        username: j['username'] as String,
        role: switch (j['role']) { 'MANAGER' => Role.manager, 'EMPLOYEE' => Role.employee, _ => null },
        ownedStores: [for (final s in j['ownedStores'] as List? ?? []) OwnedStore.fromJson(s as Map<String, dynamic>)],
        memberships: [for (final m in j['memberships'] as List? ?? []) Membership.fromJson(m as Map<String, dynamic>)],
      );
}
