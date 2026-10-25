import '../models/user.dart';
import 'api_service.dart';

/// 로그인한 사용자와 지금 보고 있는 매장. 화면들은 storeId를 여기서 꺼내 API를 부른다.
///
/// 토큰은 아직 메모리에만 둔다 (앱을 끄면 다시 로그인). 자동 로그인을 붙일 때
/// flutter_secure_storage 같은 저장소에 token을 저장하고 앱 시작 때 [refreshMe]를 부르면 된다.
class Session {
  Session._();
  static final Session instance = Session._();

  final ApiService _api = ApiService();

  Me? me;

  /// 지금 화면에서 다루는 매장 (점주는 소유 매장, 근로자는 승인된 합류 매장)
  int? storeId;

  bool get isLoggedIn => _api.token != null;

  /// 점주가 지금 보고 있는 매장 (이름·코드). 시연 중이거나 매장이 없으면 null
  OwnedStore? get currentOwnedStore => me?.ownedStores.where((s) => s.id == storeId).firstOrNull;

  Future<Me> login(String username, String password) async {
    final res = await _api.post('/api/auth/login', data: {'username': username, 'password': password});
    _api.token = res['token'] as String;
    return refreshMe();
  }

  Future<void> signup(String username, String password, Role role) =>
      _api.post('/api/auth/signup', data: {'username': username, 'password': password, 'role': role.name.toUpperCase()});

  /// A06 역할 선택. 역할이 토큰에 들어 있어서 서버가 새 토큰을 준다.
  /// 매장을 등록했거나 합류 신청한 계정은 서버가 막는다 (ApiException)
  Future<Me> changeRole(Role role) async {
    final res = await _api.patch('/api/users/me/role', data: {'role': role.name.toUpperCase()});
    _api.token = res['token'] as String;
    return refreshMe();
  }

  Future<Me> refreshMe() async {
    final m = Me.fromJson(await _api.get('/api/users/me') as Map<String, dynamic>);
    me = m;
    storeId ??= m.ownedStores.isNotEmpty
        ? m.ownedStores.first.id
        : m.memberships.where((x) => x.isApproved).map((x) => x.storeId).firstOrNull;
    return m;
  }

  void logout() {
    _api.token = null;
    me = null;
    storeId = null;
  }

  /// storeId가 꼭 있어야 하는 API 앞에서 쓴다
  int requireStoreId() {
    final id = storeId;
    if (id == null) throw ApiException('매장 정보가 없어요. 매장에 합류하거나 매장을 등록해 주세요.');
    return id;
  }
}
