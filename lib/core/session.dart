import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

/// 로그인한 사용자와 지금 보고 있는 매장. 화면들은 storeId를 여기서 꺼내 API를 부른다.
///
/// 토큰(액세스·리프레시)과 현재 매장은 shared_preferences(웹은 브라우저 저장소)에 저장해서, 새로고침하거나 앱을 다시 켜도
/// 스플래시(A01)에서 [restore]로 로그인 상태를 되살린다. 액세스 토큰이 만료되면 ApiService가 리프레시 토큰으로
/// 다시 받아 오고([_save]로 저장), 그것도 안 되거나(14일 지남) 로그아웃하면 지운다.
class Session {
  Session._() {
    _api.onTokensRefreshed = _save;
  }
  static final Session instance = Session._();

  static const _tokenKey = 'thyme.token';
  static const _refreshKey = 'thyme.refreshToken';
  static const _storeKey = 'thyme.storeId';

  final ApiService _api = ApiService();

  Me? me;

  int? _storeId;

  /// 지금 화면에서 다루는 매장 (점주는 소유 매장, 근로자는 승인된 합류 매장)
  int? get storeId => _storeId;
  set storeId(int? id) {
    _storeId = id;
    _save();
  }

  bool get isLoggedIn => _api.token != null;

  /// 점주가 지금 보고 있는 매장 (이름·코드). 매장이 없으면 null
  OwnedStore? get currentOwnedStore => me?.ownedStores.where((s) => s.id == storeId).firstOrNull;

  /// 근로자가 지금 보고 있는 합류 매장. 없으면 null
  Membership? get currentMembership => me?.memberships.where((m) => m.storeId == storeId).firstOrNull;

  Future<Me> login(String username, String password) async {
    final res = await _api.post('/api/auth/login', data: {'username': username, 'password': password});
    _api.token = res['token'] as String;
    _api.refreshToken = res['refreshToken'] as String?;
    await _save();
    return refreshMe();
  }

  Future<void> signup(String username, String password, Role role) =>
      _api.post('/api/auth/signup', data: {'username': username, 'password': password, 'role': role.name.toUpperCase()});

  /// A06 역할 선택. 역할이 토큰에 들어 있어서 서버가 새 액세스 토큰을 준다 (리프레시 토큰은 그대로 쓴다).
  /// 매장을 등록했거나 합류 신청한 계정은 서버가 막는다 (ApiException)
  Future<Me> changeRole(Role role) async {
    final res = await _api.patch('/api/users/me/role', data: {'role': role.name.toUpperCase()});
    _api.token = res['token'] as String;
    await _save();
    return refreshMe();
  }

  Future<Me> refreshMe() async {
    final m = Me.fromJson(await _api.get('/api/users/me') as Map<String, dynamic>);
    me = m;
    // 저장돼 있던 매장이 더 이상 내 매장이 아니면(승인 취소 등) 다시 고른다
    final valid = {
      ...m.ownedStores.map((s) => s.id),
      ...m.memberships.where((x) => x.isApproved).map((x) => x.storeId),
    };
    if (_storeId == null || !valid.contains(_storeId)) {
      storeId = m.ownedStores.isNotEmpty
          ? m.ownedStores.first.id
          : m.memberships.where((x) => x.isApproved).map((x) => x.storeId).firstOrNull;
    }
    return m;
  }

  /// 앱 시작(A01): 저장된 토큰이 있으면 /me 로 확인해서 돌려준다. 없거나 만료(401)면 null
  /// 서버에 닿지 못하면(잠든 무료 서버, 오프라인) ApiException을 그대로 던진다 → 스플래시가 다시 시도를 보여 준다
  Future<Me?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return null;
    _api.token = token;
    _api.refreshToken = prefs.getString(_refreshKey);
    _storeId = prefs.getInt(_storeKey);
    try {
      return await refreshMe();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await logout();
        return null;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    _api.token = null;
    _api.refreshToken = null;
    me = null;
    _storeId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_storeKey);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _api.token;
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
    final refresh = _api.refreshToken;
    if (refresh == null) {
      await prefs.remove(_refreshKey);
    } else {
      await prefs.setString(_refreshKey, refresh);
    }
    if (_storeId == null) {
      await prefs.remove(_storeKey);
    } else {
      await prefs.setInt(_storeKey, _storeId!);
    }
  }

  /// storeId가 꼭 있어야 하는 API 앞에서 쓴다
  int requireStoreId() {
    final id = storeId;
    if (id == null) throw ApiException('매장 정보가 없어요. 매장에 합류하거나 매장을 등록해 주세요.');
    return id;
  }
}
