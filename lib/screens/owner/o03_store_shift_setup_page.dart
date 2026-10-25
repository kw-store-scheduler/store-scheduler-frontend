import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/session.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'o06_exception_days_page.dart';

class StoreShiftSetupPage extends StatefulWidget {
  const StoreShiftSetupPage({super.key});

  @override
  State<StoreShiftSetupPage> createState() => _StoreShiftSetupPageState();
}

class _StoreShiftSetupPageState extends State<StoreShiftSetupPage> {
  bool _isSplitShiftEnabled = false;
  // 백엔드에 점주 근무 포함 설정이 없어서 화면에만 있다 (저장하지 않음)
  bool _isOwnerWorking = true;
  bool _saving = false;

  // 시연용 교대 (시안 값). 로그인했으면 GET /shifts (업종 기본 교대)로 바꾼다
  List<(int? id, String name, String start, String end)> _shiftRows = const [
    (null, "오픈", "09:00", "14:00"),
    (null, "미들", "12:00", "18:00"),
    (null, "마감", "17:00", "22:00"),
  ];

  // 요일별 필요 인원 데이터 (교대 순서대로, 월~일)
  List<List<int>> _minStaff = [
    [1, 1, 1, 1, 1, 2, 2], // 오픈 (월~일)
    [2, 2, 2, 2, 2, 3, 3], // 미들
    [1, 1, 1, 1, 2, 2, 2], // 마감
  ];

  final List<String> _days = weekdayLabels;

  @override
  void initState() {
    super.initState();
    if (Session.instance.isLoggedIn) _load();
  }

  Future<void> _load() async {
    try {
      final api = StoreApi();
      final shifts = await api.shifts();
      final store = await api.current();
      if (!mounted) return;
      setState(() {
        _shiftRows = [for (final s in shifts) (s.id, s.name, hhmm(s.startTime), hhmm(s.endTime))];
        _minStaff = [for (final s in shifts) List.generate(7, s.minStaffOn)];
        _isSplitShiftEnabled = store.allowSplitShift;
      });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// 교대 길이 (자정을 넘는 야간 교대도 계산)
  static String _duration(String start, String end) {
    int minutes(String t) => int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3, 5));
    var d = minutes(end) - minutes(start);
    if (d <= 0) d += 24 * 60;
    return d % 60 == 0 ? "${d ~/ 60}시간" : "${d ~/ 60}시간 ${d % 60}분";
  }

  /// 요일별 최소 인원과 쪼개기 교대를 저장하고 O06으로
  Future<void> _next() async {
    if (Session.instance.isLoggedIn) {
      setState(() => _saving = true);
      try {
        final api = StoreApi();
        for (var i = 0; i < _shiftRows.length; i++) {
          final id = _shiftRows[i].$1;
          if (id != null) await api.replaceDayStaffing(id, _minStaff[i]);
        }
        await api.updateSettings(allowSplitShift: _isSplitShiftEnabled);
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        return;
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExceptionDaysPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 3, total: 6, group: '매장 등록', owner: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "교대와 요일별 인원",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "여기서 정한 교대가 근로자 신청 화면의 칸이 돼요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // 상단 탭 (정해진 교대 / 시간 자유)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ThymeColor.surfaceSub,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: ThymeColor.surface,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: ThymeColor.text.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            alignment: Alignment.center,
                            child: const Text("정해진 교대", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: Text("시간 자유 (30분 단위)", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 교대 리스트
                  for (final (_, name, start, end) in _shiftRows) ...[
                    _buildShiftRow(name, "$start~$end", _duration(start, end)),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 8),

                  // 쪼개기 교대 토글 (에러 수정된 부분)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("쪼개기 교대 (하루 2번 근무)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                          SizedBox(height: 4),
                          Text("끄면 근로자에게 묻지 않아요", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                        ],
                      ),
                      Switch(
                        value: _isSplitShiftEnabled,
                        onChanged: (val) => setState(() => _isSplitShiftEnabled = val),
                        activeTrackColor: ThymeColor.primary, // 스위치 켜짐 = 딥 나이트
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),

                  // 요일별 최소 인원 표
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("요일별 최소 인원", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      Text("칸을 누르면 +1", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 인원 설정 그리드 (가로: 요일, 세로: 교대)
                  Row(
                    children: [
                      const SizedBox(width: 40), // 교대명 라벨 공간
                      ..._days.map((day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ThymeColor.forWeekday(day, fallback: ThymeColor.textSub),
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  ...List.generate(_shiftRows.length, (shiftIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(_shiftRows[shiftIndex].$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                          ),
                          ...List.generate(7, (dayIndex) {
                            int count = _minStaff[shiftIndex][dayIndex];
                            bool isWeekend = dayIndex >= 5;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _minStaff[shiftIndex][dayIndex] = count >= 5 ? 0 : count + 1; // 0~5 순환 (0명 = 그 요일은 이 교대 없음)
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isWeekend ? ThymeColor.text : ThymeColor.surfaceSub,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$count",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isWeekend ? ThymeColor.surface : ThymeColor.text,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 12),
                  Text("목표 인원 중 최소 +1명 시작해요 · 하루 평균 5명", style: TextStyle(fontSize: 11, color: ThymeColor.disabled)),
                  const SizedBox(height: 24),

                  // 점주 근무 포함 여부 토글 (에러 수정된 부분)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("점주·매니저도 근무에 넣기 · 주 3일 오픈", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      Switch(
                        value: _isOwnerWorking,
                        onChanged: (val) => setState(() => _isOwnerWorking = val),
                        activeTrackColor: ThymeColor.primary, // 스위치 켜짐 = 딥 나이트
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // 하단 다음 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _saving ? null : _next, child: Text(_saving ? "저장 중…" : "다음 · 예외일")),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 교대 정보 한 줄 위젯
  Widget _buildShiftRow(String name, String time, String duration) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            const SizedBox(width: 16),
            Text(time, style: const TextStyle(fontSize: 15, color: ThymeColor.text)),
          ],
        ),
        Text(duration, style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
      ],
    );
  }
}