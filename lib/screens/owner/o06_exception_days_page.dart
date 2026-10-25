import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/session.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'o04_curation_page.dart';

/// 목록 한 줄 (시연 데이터와 서버 예외일을 같은 모양으로 그린다)
class _ExceptionDay {
  const _ExceptionDay({required this.when, required this.kind, required this.icon, required this.detail, required this.change, required this.dates, this.range = true});

  final String when; // 목록에 보이는 날짜 (예: "12/18–20", "매주 화·금")
  final String kind; // 분류: 입고·세일 행사·시즌·공휴일 전날
  final IconData icon;
  final String detail;
  final String change; // 오른쪽 요약 (예: "+1", "-1h", "역량")
  final bool Function(DateTime) dates;
  final bool range; // 달력 칸을 칠할지 (매주 반복은 점만)
}

IconData _iconOf(ExceptionCategory c) => switch (c) {
      ExceptionCategory.delivery => Icons.inventory_2_outlined,
      ExceptionCategory.sale => Icons.sell_outlined,
      ExceptionCategory.season => Icons.star_outline,
      ExceptionCategory.holidayEve => Icons.calendar_today_outlined,
      ExceptionCategory.other => Icons.label_outline,
    };

/// O06 예외일 캘린더 (매장 등록 4/6). 입고일·행사·명절처럼 인원이 달라지는 날만 적는다
///
/// 로그인했으면 다음 달의 예외일(GET /staffing-exceptions)과 공휴일(GET /holidays)을 보여 주고 추가할 수 있다.
/// 시안의 "매주 화·금 입고 → 발주 가능자 필수"는 백엔드에서 예외일이 아니라 O04 시간대별 필요 역량(요일 지정)이다.
class ExceptionDaysPage extends StatefulWidget {
  const ExceptionDaysPage({super.key});

  @override
  State<ExceptionDaysPage> createState() => _ExceptionDaysPageState();
}

class _ExceptionDaysPageState extends State<ExceptionDaysPage> {
  bool get _live => Session.instance.isLoggedIn;

  // 시연은 시안 예시 달, 서버 연결은 다음 달
  late final DateTime _month = _live ? DateTime(DateTime.now().year, DateTime.now().month + 1) : DateTime(2026, 12);

  List<StaffingException> _serverExceptions = [];
  Map<DateTime, String> _holidays = {};

  static final _demo = [
    _ExceptionDay(
      when: "매주 화·금",
      kind: "입고",
      icon: Icons.inventory_2_outlined,
      detail: "오픈에 발주·입고 가능자 1명 필수",
      change: "역량",
      dates: (d) => d.weekday == DateTime.tuesday || d.weekday == DateTime.friday,
      range: false,
    ),
    _ExceptionDay(
      when: "12/18–20",
      kind: "세일 행사",
      icon: Icons.sell_outlined,
      detail: "미들·마감 +1명",
      change: "+1",
      dates: (d) => d.day >= 18 && d.day <= 20,
    ),
    _ExceptionDay(
      when: "12/24–25",
      kind: "시즌",
      icon: Icons.star_outline,
      detail: "모든 교대 +1명 · 마감 23시까지",
      change: "+1",
      dates: (d) => d.day == 24 || d.day == 25,
    ),
    _ExceptionDay(
      when: "12/31",
      kind: "공휴일 전날",
      icon: Icons.calendar_today_outlined,
      detail: "마감 21시 조기 종료",
      change: "-1h",
      dates: (d) => d.day == 31,
    ),
  ];

  List<_ExceptionDay> get _items => _live ? [for (final e in _serverExceptions) _fromServer(e)] : _demo;

  static String _md(DateTime d) => "${d.month}/${d.day}";

  static _ExceptionDay _fromServer(StaffingException e) {
    final end = e.endDate;
    final when = end == null || end == e.date
        ? _md(e.date)
        : (end.month == e.date.month ? "${_md(e.date)}–${end.day}" : "${_md(e.date)}–${_md(end)}");
    final change = e.deltaStaff != null
        ? (e.deltaStaff! > 0 ? "+${e.deltaStaff}" : "${e.deltaStaff}")
        : (e.minStaff == 0 ? "휴점" : "${e.minStaff ?? 0}명");
    final target = e.shiftName ?? "모든 교대";
    final detail = [
      e.deltaStaff != null ? "$target $change명" : (e.minStaff == 0 ? "$target 쉬어요" : "$target ${e.minStaff}명"),
      if (e.note != null && e.note!.isNotEmpty) e.note!,
    ].join(" · ");
    return _ExceptionDay(when: when, kind: e.category.label, icon: _iconOf(e.category), detail: detail, change: change, dates: e.covers);
  }

  @override
  void initState() {
    super.initState();
    if (_live) _load();
  }

  Future<void> _load() async {
    try {
      final api = StoreApi();
      final from = _month;
      final to = DateTime(_month.year, _month.month + 1, 0);
      final exceptions = await api.exceptions(from, to);
      final holidays = await api.holidays(_month.year);
      if (!mounted) return;
      setState(() {
        _serverExceptions = exceptions;
        _holidays = holidays;
      });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  bool _hasDot(DateTime d) => _items.any((e) => e.dates(d)) || _holidays.containsKey(d);
  bool _isRange(DateTime d) => _items.any((e) => e.range && e.dates(d));

  void _next(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CurationPage()));

  Future<void> _add() async {
    if (!_live) return; // 시연 중에는 시안 목록만
    final added = await showModalBottomSheet<StaffingException>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddExceptionSheet(month: _month),
    );
    if (added == null) return;
    try {
      await StoreApi().addException(added);
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(
        step: 4,
        total: 6,
        group: '매장 등록',
        owner: true,
        actions: [
          TextButton(
            onPressed: () => _next(context),
            child: const Text("건너뛰기", style: TextStyle(color: ThymeColor.textSub, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("평소와 다른 날", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 12),
                  const Text(
                    "입고일·행사·명절처럼 인원이 달라지는 날만 적어요.\n나머지는 요일 템플릿대로예요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _buildCalendar(context),
                  const SizedBox(height: 10),
                  _buildList(context),
                  const SizedBox(height: 10),
                  // 안내 = 페리윙클 배너
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(14)),
                    child: const Text(
                      "매주 반복되는 일(입고일 발주 등)은 다음 단계 '필요한 역량'에서 요일로 정해요.",
                      style: TextStyle(fontSize: 13, color: ThymeColor.infoText, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => _next(context), child: const Text("다음 · 필요한 역량")),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    const weekdays = ["일", "월", "화", "수", "목", "금", "토"];
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = DateTime(_month.year, _month.month, 1).weekday % 7; // 일요일 시작
    final cells = <DateTime?>[
      for (var i = 0; i < lead; i++) null,
      for (var d = 1; d <= days; d++) DateTime(_month.year, _month.month, d),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${_month.year}. ${_month.month}", style: ThymeTheme.mono(context, size: 17)),
              const Row(children: [
                Icon(Icons.circle, size: 6, color: ThymeColor.textSub),
                SizedBox(width: 4),
                Text("예외일 · 공휴일 자동", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Center(
                    child: Text(w, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.forWeekday(w))),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.15,
            children: [for (final d in cells) d == null ? const SizedBox() : _buildDay(context, d)],
          ),
        ],
      ),
    );
  }

  Widget _buildDay(BuildContext context, DateTime d) {
    // 공휴일은 일요일처럼 dangerText (가이드 2장 Do 6)
    final weekday = _holidays.containsKey(d) ? "일" : weekdayLabels[d.weekday - 1];
    return Container(
      // 기간 예외 = 라벤더 틴트 칸 (분류는 상태 색을 쓰지 않는다)
      decoration: BoxDecoration(color: _isRange(d) ? ThymeColor.selectedSoft : null, borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("${d.day}", style: ThymeTheme.mono(context, size: 15, color: ThymeColor.forWeekday(weekday))),
          const SizedBox(height: 3),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: _hasDot(d) ? ThymeColor.text : Colors.transparent, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final items = _items;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text("아직 예외일이 없어요. 평소와 같은 날이면 그냥 넘어가도 돼요.",
                  style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
            ),
          for (final e in items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(e.when, style: ThymeTheme.mono(context, size: 15)),
                          const SizedBox(width: 8),
                          _buildKindChip(e.kind, e.icon),
                        ]),
                        const SizedBox(height: 6),
                        Text(e.detail, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                      ],
                    ),
                  ),
                  Text(e.change, style: ThymeTheme.mono(context, size: 16)),
                ],
              ),
            ),
            const Divider(),
          ],
          InkWell(
            onTap: _add,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(children: [
                Text("+ 예외일 추가", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// 분류 칩 = 라벤더 틴트 + 차콜 글자 + 선 아이콘 (가이드 1-1)
Widget _buildKindChip(String label, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: ThymeColor.selectedSoft, borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: ThymeColor.charcoal),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.charcoal)),
      ],
    ),
  );
}

/// 예외일 추가: 분류 · 날짜(기간) · 평소 대비 인원 또는 휴점 · 메모 (모든 교대에 적용)
class _AddExceptionSheet extends StatefulWidget {
  const _AddExceptionSheet({required this.month});

  final DateTime month;

  @override
  State<_AddExceptionSheet> createState() => _AddExceptionSheetState();
}

class _AddExceptionSheetState extends State<_AddExceptionSheet> {
  ExceptionCategory _category = ExceptionCategory.sale;
  late DateTime _start = widget.month;
  late DateTime _end = widget.month;
  int _delta = 1;
  bool _closed = false; // 휴점 = 그날 모든 교대 0명
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(widget.month.year, widget.month.month - 1),
      lastDate: DateTime(widget.month.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (range != null) {
      setState(() {
        _start = range.start;
        _end = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sameDay = _start == _end;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("예외일 추가", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in ExceptionCategory.values)
                ChoiceChip(
                  label: Text(c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                  // 선택 = 딥 나이트 (가이드 4-3)
                  selectedColor: ThymeColor.primary,
                  labelStyle: TextStyle(color: _category == c ? ThymeColor.onPrimary : ThymeColor.text, fontWeight: FontWeight.bold),
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(sameDay ? "${_start.month}/${_start.day}" : "${_start.month}/${_start.day} – ${_end.month}/${_end.day}"),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: ThymeColor.primary,
            activeThumbColor: ThymeColor.onPrimary,
            title: const Text("휴점 (모든 교대 0명)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            value: _closed,
            onChanged: (v) => setState(() => _closed = v),
          ),
          if (!_closed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("평소 대비 인원", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                Row(children: [
                  IconButton(
                    onPressed: () => setState(() => _delta = _delta - 1 == 0 ? -1 : (_delta - 1).clamp(-5, 5)),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 40,
                    child: Center(child: Text(_delta > 0 ? "+$_delta" : "$_delta", style: ThymeTheme.mono(context, size: 18))),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _delta = _delta + 1 == 0 ? 1 : (_delta + 1).clamp(-5, 5)),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ]),
              ],
            ),
          const SizedBox(height: 8),
          TextField(controller: _note, decoration: const InputDecoration(hintText: "메모 (선택) · 예: 겨울 세일")),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(
                context,
                StaffingException(
                  date: _start,
                  endDate: sameDay ? null : _end,
                  category: _category,
                  deltaStaff: _closed ? null : _delta,
                  minStaff: _closed ? 0 : null,
                  note: _note.text.trim(),
                ),
              ),
              child: const Text("추가"),
            ),
          ),
        ],
      ),
    );
  }
}
