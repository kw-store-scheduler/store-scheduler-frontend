import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_service.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../theme/thyme_colors.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'o06_exception_days_page.dart';

/// O03 교대와 요일별 인원 (매장 등록 3/6).
/// 교대 = GET /shifts (업종 기본 교대). 추가·삭제는 바로 서버에, 이름·시간·요일별 인원은 '다음'에서 한꺼번에 저장한다.
class StoreShiftSetupPage extends StatefulWidget {
  const StoreShiftSetupPage({super.key, this.editing = false});

  /// 매장 설정(P08)에서 고칠 때: 진행바 대신 제목, '다음' 대신 저장 후 돌아가기
  final bool editing;

  @override
  State<StoreShiftSetupPage> createState() => _StoreShiftSetupPageState();
}

/// 화면에서 고치는 교대 한 줄
class _Row {
  _Row(this.info)
      : name = info.name,
        start = _toMin(info.startTime),
        end = _toMin(info.endTime),
        minStaff = List.generate(7, info.minStaffOn);

  final ShiftInfo info;
  String name;
  int start; // 0시부터 분 (30분 단위)
  int end;
  final List<int> minStaff; // 월~일

  bool get edited => name != info.name || start != _toMin(info.startTime) || end != _toMin(info.endTime);
  int get minutes => end - start <= 0 ? end - start + 24 * 60 : end - start;
}

int _toMin(String t) => int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3, 5));

String _fmt(int m) => "${(m ~/ 60 % 24).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}";

String _duration(int minutes) => minutes % 60 == 0 ? "${minutes ~/ 60}시간" : "${minutes ~/ 60}시간 ${minutes % 60}분";

class _StoreShiftSetupPageState extends State<StoreShiftSetupPage> {
  List<_Row>? _rows;
  bool _split = false;
  bool _freeTime = false; // 탭: 정해진 교대 / 시간 자유 (30분 단위)
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final api = StoreApi();
      final shifts = await api.shifts();
      final store = await api.current();
      if (!mounted) return;
      setState(() {
        _rows = [for (final s in shifts) _Row(s)];
        _split = store.allowSplitShift;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  /// 교대 추가·수정 시트. [row]가 없으면 새 교대
  Future<void> _editShift([_Row? row]) async {
    final result = await showModalBottomSheet<_ShiftEdit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ShiftSheet(
        name: row?.name ?? "",
        start: row?.start ?? 9 * 60,
        end: row?.end ?? 13 * 60,
        canDelete: row != null && _rows!.length > 1,
      ),
    );
    if (result == null || !mounted) return;
    if (result.delete) return _delete(row!);
    if (row != null) {
      setState(() {
        row.name = result.name;
        row.start = result.start;
        row.end = result.end;
      });
      return;
    }
    setState(() => _saving = true);
    try {
      final created = await StoreApi().addShift(name: result.name, startTime: _fmt(result.start), endTime: _fmt(result.end));
      if (mounted) setState(() => _rows!.add(_Row(created)));
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(_Row row) async {
    setState(() => _saving = true);
    try {
      await StoreApi().deleteShift(row.info.id);
      if (mounted) setState(() => _rows!.remove(row));
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 칸을 누르면: −/+ 와 직접 입력
  Future<void> _editCell(_Row row, int day) async {
    final result = await showModalBottomSheet<(int, bool)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StaffSheet(title: "${row.name} · ${weekdayLabels[day]}요일", value: row.minStaff[day]),
    );
    if (result == null || !mounted) return;
    final (value, allDays) = result;
    setState(() {
      if (allDays) {
        row.minStaff.fillRange(0, 7, value);
      } else {
        row.minStaff[day] = value;
      }
    });
  }

  Future<void> _next() async {
    final rows = _rows!;
    if (rows.isEmpty) return _toast("교대를 하나 이상 만들어 주세요.");
    setState(() => _saving = true);
    try {
      final api = StoreApi();
      for (final r in rows) {
        if (r.edited) await api.updateShift(r.info, name: r.name, startTime: _fmt(r.start), endTime: _fmt(r.end));
        await api.replaceDayStaffing(r.info.id, r.minStaff);
      }
      await api.updateSettings(allowSplitShift: _split);
      // 다시 돌아와도 저장한 값이 '원래 값'이 되게
      final fresh = await api.shifts();
      if (!mounted) return;
      setState(() => _rows = [for (final s in fresh) _Row(s)]);
      if (widget.editing) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장했어요. 다음 근무표부터 반영돼요.")));
        Navigator.pop(context);
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ExceptionDaysPage()));
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: widget.editing ? thymeEditAppBar('교대 시간대 · 인원') : const ThymeStepAppBar(step: 3, total: 6, group: '매장 등록', owner: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("교대와 요일별 인원", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 10),
                  const Text("여기서 정한 교대가 근로자 신청 화면의 칸이 돼요.", style: TextStyle(fontSize: 15, color: ThymeColor.textSub)),
                  const SizedBox(height: 20),
                  if (_error != null)
                    _errorBox()
                  else if (rows == null)
                    const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                  else ...[
                    _tabs(),
                    const SizedBox(height: 12),
                    _freeTime ? _freeTimeCard(rows) : _shiftCard(rows),
                    const SizedBox(height: 12),
                    _staffCard(rows),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: rows == null || _saving ? null : _next,
                  child: Text(_saving ? "저장 중…" : (widget.editing ? "저장" : "다음 · 예외일")),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: ThymeColor.border, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          for (final (free, label) in const [(false, "정해진 교대"), (true, "시간 자유 (30분 단위)")])
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _freeTime = free),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _freeTime == free ? ThymeColor.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _freeTime == free ? ThymeColor.text : ThymeColor.textSub,
                      )),
                ),
              ),
            ),
        ]),
      );

  /// 정해진 교대: 줄을 누르면 이름·시간 편집
  Widget _shiftCard(List<_Row> rows) => _card(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(children: [
          for (final r in rows) ...[
            InkWell(
              onTap: _saving ? null : () => _editShift(r),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(children: [
                  SizedBox(width: 72, child: Text(r.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                  Expanded(child: Text("${_fmt(r.start)}–${_fmt(r.end)}", style: ThymeTheme.mono(context, size: 17, color: ThymeColor.text))),
                  Text(_duration(r.minutes), style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined, size: 18, color: ThymeColor.icon),
                ]),
              ),
            ),
            const Divider(height: 1),
          ],
          InkWell(
            onTap: _saving ? null : () => _editShift(),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(children: [
                Icon(Icons.add, size: 20, color: ThymeColor.text),
                SizedBox(width: 6),
                Text("교대 추가", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              ]),
            ),
          ),
          const Divider(height: 1),
          _splitRow(),
        ]),
      );

  /// 시간 자유: 교대 시작·끝을 30분씩 옮긴다
  Widget _freeTimeCard(List<_Row> rows) => _card(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("시간대를 30분 단위로 직접 맞춰요. 근로자 신청 화면에는 이 시간대가 칸으로 나와요.",
                style: TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.5)),
            const SizedBox(height: 12),
            for (final r in rows) ...[
              Row(children: [
                Expanded(child: Text(r.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                Text(_duration(r.minutes), style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
              ]),
              const SizedBox(height: 8),
              _timeline(r),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _HalfHourStepper(label: "시작", value: r.start, onChanged: (v) => setState(() => r.start = v))),
                const SizedBox(width: 10),
                Expanded(child: _HalfHourStepper(label: "끝", value: r.end, onChanged: (v) => setState(() => r.end = v))),
              ]),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 4),
            ],
            _splitRow(),
          ],
        ),
      );

  /// 0~24시 막대 위에 교대 구간 (밤을 넘기면 두 조각)
  Widget _timeline(_Row r) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final end = r.start + r.minutes;
        Widget bar(int from, int to) => Positioned(
              left: w * from / 1440,
              width: w * (to - from) / 1440,
              top: 0,
              bottom: 0,
              child: Container(decoration: BoxDecoration(color: ThymeColor.primary, borderRadius: BorderRadius.circular(4))),
            );
        return SizedBox(
          height: 10,
          child: Stack(children: [
            Positioned.fill(child: Container(decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(4)))),
            if (end <= 1440) bar(r.start, end) else ...[bar(r.start, 1440), bar(0, end - 1440)],
          ]),
        );
      });

  Widget _splitRow() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("쪼개기 교대 (하루 2번 근무)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                SizedBox(height: 4),
                Text("끄면 근로자에게 묻지 않아요", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
              ],
            ),
          ),
          Switch(value: _split, onChanged: (v) => setState(() => _split = v)),
        ]),
      );

  Widget _staffCard(List<_Row> rows) {
    final perDay = [for (var d = 0; d < 7; d++) rows.fold<int>(0, (sum, r) => sum + r.minStaff[d])];
    final avg = rows.isEmpty ? 0 : (perDay.reduce((a, b) => a + b) / 7).round();
    return _card(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Expanded(child: Text("요일별 최소 인원", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text))),
            Text("칸을 눌러 바꿔요", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const SizedBox(width: 52),
            for (final d in weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(d, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.forWeekday(d))),
                ),
              ),
          ]),
          const SizedBox(height: 6),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                SizedBox(width: 52, child: Text(r.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                for (var d = 0; d < 7; d++) Expanded(child: _cell(r, d)),
              ]),
            ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("교대를 추가하면 여기서 인원을 정해요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
            ),
          const SizedBox(height: 12),
          Text("목표 인원은 최소 +1로 시작해요 · 하루 평균 $avg명", style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
        ],
      ),
    );
  }

  Widget _cell(_Row r, int d) {
    final n = r.minStaff[d];
    // 인원이 많을수록 진하게 (시안: 1 연보라 · 2 페리윙클 · 3 이상 딥 나이트)
    final (bg, fg) = switch (n) {
      0 => (ThymeColor.surface, ThymeColor.textSub),
      1 => (ThymeColor.selectedSoft, ThymeColor.text),
      2 => (Color.lerp(ThymePalette.peri100, ThymePalette.peri300, 0.5)!, ThymeColor.text),
      _ => (ThymeColor.indigoSurface, ThymeColor.onPrimary),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _editCell(r, d),
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: n == 0
                ? BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: ThymeColor.border))
                : null,
            child: Text("$n", style: ThymeTheme.mono(context, size: 16, color: fg)),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, required EdgeInsets padding}) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
        child: child,
      );

  Widget _errorBox() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.dangerBg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_error!, style: const TextStyle(color: ThymeColor.dangerText, fontSize: 14)),
          TextButton(onPressed: _load, child: const Text("다시 불러오기")),
        ]),
      );
}

/// 시간 자유 탭: [−] 09:00 [+] (30분씩, 하루를 돌아간다)
class _HalfHourStepper extends StatelessWidget {
  const _HalfHourStepper({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          IconButton(
            tooltip: "$label 30분 앞으로",
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => onChanged((value - 30) % 1440),
          ),
          Expanded(
            child: Column(children: [
              Text(label, style: const TextStyle(fontSize: 11, color: ThymeColor.textSub)),
              Text(_fmt(value), style: ThymeTheme.mono(context, size: 15, color: ThymeColor.text)),
            ]),
          ),
          IconButton(
            tooltip: "$label 30분 뒤로",
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => onChanged((value + 30) % 1440),
          ),
        ]),
      );
}

class _ShiftEdit {
  const _ShiftEdit({this.name = "", this.start = 0, this.end = 0, this.delete = false});

  final String name;
  final int start;
  final int end;
  final bool delete;
}

/// 교대 이름 + 시작·끝 (30분 단위 휠)
class _ShiftSheet extends StatefulWidget {
  const _ShiftSheet({required this.name, required this.start, required this.end, required this.canDelete});

  final String name;
  final int start;
  final int end;
  final bool canDelete;

  @override
  State<_ShiftSheet> createState() => _ShiftSheetState();
}

class _ShiftSheetState extends State<_ShiftSheet> {
  late final _name = TextEditingController(text: widget.name);
  late int _start = widget.start - widget.start % 30;
  late int _end = widget.end - widget.end % 30;
  bool _confirmDelete = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Widget _wheel(String label, int value, ValueChanged<int> onChanged) => Expanded(
        child: Column(children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
          SizedBox(
            height: 150,
            child: CupertinoPicker(
              itemExtent: 36,
              scrollController: FixedExtentScrollController(initialItem: value ~/ 30),
              onSelectedItemChanged: (i) => onChanged(i * 30),
              children: [for (var i = 0; i < 48; i++) Center(child: Text(_fmt(i * 30), style: ThymeTheme.mono(context, size: 18)))],
            ),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final name = _name.text.trim();
    final valid = name.isNotEmpty && _start != _end;
    final minutes = _end - _start <= 0 ? _end - _start + 1440 : _end - _start;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name.isEmpty ? "교대 추가" : "교대 수정", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: "이름 (예: 오전, 오후, 야간)"),
            ),
            const SizedBox(height: 16),
            Row(children: [
              _wheel("시작", _start, (v) => setState(() => _start = v)),
              _wheel("끝", _end, (v) => setState(() => _end = v)),
            ]),
            Center(
              child: Text(_start == _end ? "시작과 끝이 같아요" : "${_duration(minutes)}${_end <= _start ? " · 다음 날까지" : ""}",
                  style: TextStyle(fontSize: 13, color: _start == _end ? ThymeColor.dangerText : ThymeColor.textSub)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: valid ? () => Navigator.pop(context, _ShiftEdit(name: name, start: _start, end: _end)) : null,
                child: Text(widget.name.isEmpty ? "추가" : "적용"),
              ),
            ),
            if (widget.canDelete) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: ThymeColor.dangerText),
                  onPressed: () => _confirmDelete
                      ? Navigator.pop(context, const _ShiftEdit(delete: true))
                      : setState(() => _confirmDelete = true),
                  child: Text(_confirmDelete ? "정말 삭제할까요? 한 번 더 누르면 삭제돼요" : "이 교대 삭제"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 최소 인원 한 칸: −/+ 와 직접 입력. 결과 = (인원, 모든 요일에 적용)
class _StaffSheet extends StatefulWidget {
  const _StaffSheet({required this.title, required this.value});

  final String title;
  final int value;

  @override
  State<_StaffSheet> createState() => _StaffSheetState();
}

class _StaffSheetState extends State<_StaffSheet> {
  static const _max = 30;
  late final _text = TextEditingController(text: "${widget.value}");
  late int _value = widget.value;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _set(int v) {
    _value = v.clamp(0, _max);
    _text.text = "$_value";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 4),
              const Text("최소 인원 · 0명이면 그 요일엔 이 교대가 없어요", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton.filledTonal(
                  tooltip: "1명 줄이기",
                  iconSize: 28,
                  onPressed: _value > 0 ? () => _set(_value - 1) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 96,
                  child: TextField(
                    controller: _text,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                    style: ThymeTheme.mono(context, size: 30, color: ThymeColor.text),
                    decoration: const InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
                    onChanged: (t) => setState(() => _value = (int.tryParse(t) ?? 0).clamp(0, _max)),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: "1명 늘리기",
                  iconSize: 28,
                  onPressed: _value < _max ? () => _set(_value + 1) : null,
                  icon: const Icon(Icons.add),
                ),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.pop(context, (_value, false)), child: const Text("적용")),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: () => Navigator.pop(context, (_value, true)), child: const Text("이 교대 모든 요일에 적용")),
              ),
            ],
          ),
        ),
      );
}
