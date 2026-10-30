import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/models/owner.dart';
import 'package:thyme_frontend/models/worker.dart';

/// 급여 응답의 공제·실수령 (백엔드 8fcafac PayrollService.EmployeePayroll, HomeController.MonthlyPayResponse)
void main() {
  test('GET /payroll 한 줄: 공제 종류·공제액·실수령, 휴일 가산', () {
    final r = PayrollRow.fromJson({
      'employeeId': 3,
      'employeeName': '김지수',
      'totalHours': 40.0,
      'hourlyWage': 10320,
      'regularWage': 412800,
      'weeklyHolidayPay': 82560,
      'nightPay': 0,
      'overtimePay': 0,
      'holidayPay': 15480,
      'totalPay': 510840,
      'deductionType': 'FREELANCE',
      'deduction': 16850,
      'netPay': 493990,
    });
    expect(r.deductionType, PayDeduction.freelance);
    expect(r.deductionType.label, '3.3%');
    expect(r.holidayPay, 15480);
    expect((r.deduction, r.netPay), (16850, 493990));
  });

  test('옛 서버 응답(공제 필드 없음)이면 공제 0, 실수령 = 총액', () {
    final r = PayrollRow.fromJson({'employeeId': 3, 'employeeName': '김지수', 'totalPay': 100000});
    expect(r.deductionType, PayDeduction.none);
    expect((r.deduction, r.netPay), (0, 100000));
  });

  test('공제 종류는 서버 이름으로 주고받는다', () {
    for (final d in PayDeduction.values) {
      expect(PayDeduction.fromJson(d.json), d);
    }
  });

  test('직원 홈 monthlyPay 의 공제·실수령', () {
    Map<String, dynamic> home(Map<String, dynamic> pay) => {
          'storeName': '구시대 커피',
          'employeeName': '김지수',
          'date': '2026-10-30',
          'today': {'date': '2026-10-30'},
          'monthlyPay': pay,
          'nextMonthPreferences': {'month': '2026-11', 'deadline': '2026-10-25', 'daysUntilDeadline': -5, 'submittedCount': 0, 'employeeCount': 3, 'submittedByMe': false},
        };
    final h = WorkerHome.fromJson(home({'totalHours': 40, 'totalPay': 510840, 'weeklyHolidayPay': 82560, 'deduction': 16850, 'netPay': 493990}));
    expect((h.monthPay, h.monthDeduction, h.monthNetPay), (510840, 16850, 493990));
    final old = WorkerHome.fromJson(home({'totalHours': 40, 'totalPay': 510840, 'weeklyHolidayPay': 82560}));
    expect((old.monthDeduction, old.monthNetPay), (0, 510840));
  });
}
