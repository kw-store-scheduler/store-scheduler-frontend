import '../models/store.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'session.dart';

/// 근로자 매장 합류 (J01 → J03 → J04). 백엔드 StoreController.previewByCode · StoreEmployeeController.joinStore
class JoinApi {
  JoinApi({ApiService? api, Session? session})
      : _api = api ?? ApiService(),
        _session = session ?? Session.instance;

  final ApiService _api;
  final Session _session;

  /// 서버가 만드는 매장 코드 길이 (UUID 앞 8자리, 대문자)
  static const codeLength = 8;

  /// J01: 합류 전 매장 확인. 틀린 코드면 ApiException("유효하지 않은 매장 코드입니다.")
  Future<StorePreview> preview(String storeCode) async =>
      StorePreview.fromJson(await _api.get('/api/stores/code/${storeCode.toUpperCase()}') as Map<String, dynamic>);

  /// J03: 합류 신청. 점주가 승인하기 전까지 status는 PENDING
  Future<Membership> join({
    required String storeCode,
    required String name,
    String? nickname,
    DateTime? startDate,
    bool minor = false,
    EmploymentType employmentType = EmploymentType.partTime,
  }) async {
    await _api.post('/api/stores/join/${storeCode.toUpperCase()}', data: {
      'name': name,
      if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
      if (startDate != null) 'startDate': dateParam(startDate),
      'minor': minor,
      'employmentType': employmentType == EmploymentType.fullTime ? 'FULL_TIME' : 'PART_TIME',
    });
    // 한 계정이 여러 매장에 신청할 수 있어서, 방금 신청한 것 = 마지막 것
    return (await _session.refreshMe()).memberships.last;
  }

  /// J04: 승인됐는지 다시 확인. 승인되면 세션의 현재 매장을 그 매장으로 둔다
  Future<Membership?> refresh() async {
    final me = await _session.refreshMe();
    if (me.memberships.isEmpty) return null;
    final m = me.memberships.last;
    if (m.isApproved) _session.storeId = m.storeId;
    return m;
  }
}
