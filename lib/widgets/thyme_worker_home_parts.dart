import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/owner.dart';
import '../models/store.dart';
import '../models/worker.dart';
import '../theme/thyme_theme.dart';
import 'thyme_leaf.dart';

/// 근로자 홈(H01 알바 · H02 직원)이 같이 쓰는 조각: 오늘 근무 민트 카드, 대타 요청 배너, 이번 주 줄

/// 오늘 근무 (가이드 5장: 근로자 홈 = 오늘 근무 민트 카드). 근무가 없으면 다음 근무를 알려 준다
class WorkerTodayCard extends StatelessWidget {
  const WorkerTodayCard({super.key, required this.home, required this.busy, required this.onClock, required this.onAbsent});

  final WorkerHome home;
  final bool busy;

  /// 출근 전이면 출근, 출근했으면 퇴근
  final VoidCallback onClock;
  final VoidCallback onAbsent;

  @override
  Widget build(BuildContext context) {
    final t = home.today;
    if (!t.working) {
      final next = home.week.where((d) => d.working && d.date.isAfter(home.date)).firstOrNull;
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("오늘 ${mdw(home.date)}", style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
          const SizedBox(height: 6),
          const Text("오늘은 쉬는 날이에요", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          const SizedBox(height: 6),
          Text(
            next == null ? "이번 주 남은 근무가 없어요" : "다음 근무 ${mdw(next.date)} ${next.shiftName ?? ''} ${timeRange(next.startTime!, next.endTime!)}",
            style: const TextStyle(fontSize: 14, color: ThymeColor.textSub),
          ),
        ]),
      );
    }
    final clockLabel = home.clockIn == null ? "출근하기" : (home.clockOut == null ? "퇴근하기" : "퇴근 완료");
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: ThymeColor.accent, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text("오늘 ${mdw(home.date)}${t.shiftName == null ? '' : ' · ${t.shiftName}'}",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.onAccent)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(14)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              ThymeLeaf(size: 12),
              SizedBox(width: 4),
              Text("확정", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.successText)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(timeRange(t.startTime!, t.endTime!), style: ThymeTheme.mono(context, size: 36, color: ThymeColor.onAccent)),
        ),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (home.coworkers.isNotEmpty)
                Text("함께: ${home.coworkers.join(' · ')}", style: const TextStyle(fontSize: 14, color: ThymeColor.onAccent)),
              // 출근한 뒤에는 결원 신고 대신 퇴근
              if (home.clockIn == null)
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36), foregroundColor: ThymeColor.onAccent),
                  onPressed: onAbsent,
                  child: const Text("오늘 못 나가요 ›", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                ),
            ]),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48), padding: const EdgeInsets.symmetric(horizontal: 20)),
            onPressed: busy || home.clockOut != null ? null : onClock,
            child: Text(clockLabel),
          ),
        ]),
      ]),
    );
  }
}

/// 나에게 온 대타 요청 (화면에서 가장 급한 카드 1장만 로즈)
class WorkerOfferBanner extends StatelessWidget {
  const WorkerOfferBanner({super.key, required this.offer, required this.more, required this.onTap});

  final SwapOffer offer;

  /// 이것 말고 더 온 요청 수
  final int more;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: ThymeColor.dangerBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              const ThymeLeaf(size: 36, color: ThymeColor.danger, dashed: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(more > 0 ? "대타 요청이 ${more + 1}건 왔어요" : "대타 요청이 왔어요",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 2),
                  Text("${mdw(offer.workDate)} ${hourRange(offer.startTime, offer.endTime)}시 · 예상 ${won(offer.expectedPay)}",
                      style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                ]),
              ),
              const Icon(Icons.circle, size: 8, color: ThymeColor.danger),
              const SizedBox(width: 6),
              const Text("응답 필요", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.dangerText)),
            ]),
          ),
        ),
      );
}

/// 이번 주 월~일 (근무한 날 = 민트 잎, 쉬는 날 = 점선 잎, 오늘 = 라벤더 칸)
class WorkerWeekStrip extends StatelessWidget {
  const WorkerWeekStrip({super.key, required this.week, required this.today, required this.onAll});

  final List<DaySchedule> week;
  final DateTime today;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          Row(children: [
            const Expanded(child: Text("이번 주", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text))),
            TextButton(onPressed: onAll, child: const Text("전체 근무표 →", style: TextStyle(decoration: TextDecoration.underline))),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            for (final d in week)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: DateUtils.isSameDay(d.date, today) ? ThymeColor.selectedSoft : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    Text(weekdayLabels[d.date.weekday - 1],
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: d.date.weekday == 7 ? ThymeColor.dangerText : (d.date.weekday == 6 ? ThymeColor.infoText : ThymeColor.textSub))),
                    const SizedBox(height: 4),
                    Text("${d.date.day}", style: ThymeTheme.mono(context, size: 15)),
                    const SizedBox(height: 6),
                    ThymeLeaf(size: 18, color: d.working ? ThymeColor.accent : ThymeColor.icon, dashed: !d.working),
                    const SizedBox(height: 4),
                    Text(d.working ? (d.shiftName ?? hourRange(d.startTime!, d.endTime!)) : "",
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ThymeColor.successText)),
                  ]),
                ),
              ),
          ]),
        ]),
      );
}

/// 홈 인사말 (시간대별)
String greeting(String name) {
  final h = DateTime.now().hour;
  final hello = h < 11 ? "좋은 아침이에요" : (h < 17 ? "좋은 오후예요" : "오늘도 수고했어요");
  return name.isEmpty ? hello : "$name님, $hello";
}
