import '../entities/attendance_entry.dart';
import '../entities/employee.dart';
import '../entities/leave_request.dart';
import '../entities/payslip.dart';

/// Single source of demo data for Module 7 (Human Resources).
///
/// **Why a flat seed**: same rationale as `SalesSeed` / `InventorySeed`
/// — keeps the stub repos drop-in without a backing API, lets tests
/// reach in for deterministic fixtures, and lets the demo run with the
/// shipped binary.
class HrSeed {
  static final List<Employee> employees = <Employee>[
    Employee(
      id: 'emp-001',
      name: 'Demo Approver',
      email: 'demo.approver@erp.example',
      phone: '+855 23 555 0001',
      department: 'Operations',
      position: 'COO',
      hiredAt: DateTime.utc(2022, 4, 1),
      status: EmploymentStatus.active,
      monthlySalary: r'$4,200.00',
      location: 'Phnom Penh HQ',
    ),
    Employee(
      id: 'emp-002',
      name: 'Sokha Tep',
      email: 'sokha.tep@erp.example',
      phone: '+855 92 555 0002',
      department: 'Sales',
      position: 'Head of Sales',
      hiredAt: DateTime.utc(2023, 1, 15),
      status: EmploymentStatus.active,
      monthlySalary: r'$3,200.00',
      managerId: 'emp-001',
      location: 'Phnom Penh HQ',
    ),
    Employee(
      id: 'emp-003',
      name: 'Pisey Chan',
      email: 'pisey.chan@erp.example',
      phone: '+855 12 555 0003',
      department: 'Finance',
      position: 'CFO',
      hiredAt: DateTime.utc(2022, 6, 1),
      status: EmploymentStatus.active,
      monthlySalary: r'$3,800.00',
      managerId: 'emp-001',
      location: 'Phnom Penh HQ',
    ),
    Employee(
      id: 'emp-004',
      name: 'Dara Nuon',
      email: 'dara.nuon@erp.example',
      phone: '+855 92 555 0004',
      department: 'Finance',
      position: 'Accountant',
      hiredAt: DateTime.utc(2024, 9, 12),
      status: EmploymentStatus.active,
      monthlySalary: r'$1,400.00',
      managerId: 'emp-003',
      location: 'Phnom Penh HQ',
    ),
    Employee(
      id: 'emp-005',
      name: 'Bopha Lim',
      email: 'bopha.lim@erp.example',
      phone: '+855 78 555 0005',
      department: 'Sales',
      position: 'Account Executive',
      hiredAt: DateTime.utc(2025, 2, 3),
      status: EmploymentStatus.onLeave,
      monthlySalary: r'$1,600.00',
      managerId: 'emp-002',
      location: 'Phnom Penh HQ',
    ),
    Employee(
      id: 'emp-006',
      name: 'Vibol Sok',
      email: 'vibol.sok@erp.example',
      phone: '+855 17 555 0006',
      department: 'Engineering',
      position: 'Lead Engineer',
      hiredAt: DateTime.utc(2023, 7, 22),
      status: EmploymentStatus.active,
      monthlySalary: r'$3,400.00',
      managerId: 'emp-001',
      location: 'Remote',
    ),
    Employee(
      id: 'emp-007',
      name: 'Channary Pich',
      email: 'channary.pich@erp.example',
      phone: '+855 12 555 0007',
      department: 'Engineering',
      position: 'Software Engineer',
      hiredAt: DateTime.utc(2025, 5, 18),
      status: EmploymentStatus.active,
      monthlySalary: r'$1,800.00',
      managerId: 'emp-006',
      location: 'Phnom Penh HQ',
    ),
    Employee(
      id: 'emp-008',
      name: 'Rithy Heng',
      email: 'rithy.heng@erp.example',
      phone: '+855 92 555 0008',
      department: 'Operations',
      position: 'Warehouse Lead',
      hiredAt: DateTime.utc(2024, 3, 10),
      status: EmploymentStatus.active,
      monthlySalary: r'$1,200.00',
      managerId: 'emp-001',
      location: 'Warehouse 1',
    ),
  ];

  static final List<LeaveRequest> leaveRequests = <LeaveRequest>[
    LeaveRequest(
      id: 'lv-001',
      employeeId: 'emp-005',
      employeeName: 'Bopha Lim',
      type: LeaveType.annual,
      fromDate: DateTime.utc(2026, 5, 11),
      toDate: DateTime.utc(2026, 5, 15),
      reason: 'Family wedding upcountry',
      status: LeaveRequestStatus.approved,
      requestedAt: DateTime.utc(2026, 4, 28, 9, 15),
      approvedBy: 'emp-002',
      actionedAt: DateTime.utc(2026, 4, 28, 14, 0),
    ),
    LeaveRequest(
      id: 'lv-002',
      employeeId: 'emp-004',
      employeeName: 'Dara Nuon',
      type: LeaveType.sick,
      fromDate: DateTime.utc(2026, 5, 14),
      toDate: DateTime.utc(2026, 5, 14),
      reason: 'Doctor visit — flu',
      status: LeaveRequestStatus.pending,
      requestedAt: DateTime.utc(2026, 5, 13, 8, 0),
    ),
    LeaveRequest(
      id: 'lv-003',
      employeeId: 'emp-007',
      employeeName: 'Channary Pich',
      type: LeaveType.personal,
      fromDate: DateTime.utc(2026, 5, 20),
      toDate: DateTime.utc(2026, 5, 21),
      reason: 'Visa appointment',
      status: LeaveRequestStatus.pending,
      requestedAt: DateTime.utc(2026, 5, 12, 16, 30),
    ),
    LeaveRequest(
      id: 'lv-004',
      employeeId: 'emp-008',
      employeeName: 'Rithy Heng',
      type: LeaveType.annual,
      fromDate: DateTime.utc(2026, 4, 3),
      toDate: DateTime.utc(2026, 4, 5),
      reason: 'Khmer New Year extension',
      status: LeaveRequestStatus.rejected,
      requestedAt: DateTime.utc(2026, 3, 20),
      approvedBy: 'emp-001',
      actionedAt: DateTime.utc(2026, 3, 22, 11, 0),
      decisionNote: 'Coverage gap — please reschedule',
    ),
  ];

  /// Baselines are the per-employee yearly entitlement (`totalDays`) and
  /// the days already booked at the time the seed was frozen
  /// (`usedDays`). The [computeEffectiveBalances] use case layers
  /// approved requests on top of this — so changing a request's status
  /// in the demo session shows up in the balance widget immediately.
  static final List<LeaveBalance> leaveBalances = <LeaveBalance>[
    // emp-005 already had its annual leave booked into the baseline,
    // because lv-001 (approved) predates the seed snapshot.
    LeaveBalance(
      employeeId: 'emp-005',
      type: LeaveType.annual,
      totalDays: 18,
      usedDays: 5,
    ),
    LeaveBalance(
      employeeId: 'emp-005',
      type: LeaveType.sick,
      totalDays: 10,
      usedDays: 1,
    ),
    LeaveBalance(
      employeeId: 'emp-005',
      type: LeaveType.personal,
      totalDays: 3,
      usedDays: 0,
    ),
    LeaveBalance(
      employeeId: 'emp-001',
      type: LeaveType.annual,
      totalDays: 21,
      usedDays: 4,
    ),
    LeaveBalance(
      employeeId: 'emp-001',
      type: LeaveType.sick,
      totalDays: 10,
      usedDays: 0,
    ),
    LeaveBalance(
      employeeId: 'emp-001',
      type: LeaveType.personal,
      totalDays: 5,
      usedDays: 2,
    ),
    LeaveBalance(
      employeeId: 'emp-004',
      type: LeaveType.annual,
      totalDays: 14,
      usedDays: 6,
    ),
    LeaveBalance(
      employeeId: 'emp-004',
      type: LeaveType.sick,
      totalDays: 10,
      usedDays: 2,
    ),
    LeaveBalance(
      employeeId: 'emp-004',
      type: LeaveType.personal,
      totalDays: 3,
      usedDays: 1,
    ),
    LeaveBalance(
      employeeId: 'emp-007',
      type: LeaveType.annual,
      totalDays: 14,
      usedDays: 0,
    ),
    LeaveBalance(
      employeeId: 'emp-007',
      type: LeaveType.sick,
      totalDays: 10,
      usedDays: 0,
    ),
    LeaveBalance(
      employeeId: 'emp-007',
      type: LeaveType.personal,
      totalDays: 3,
      usedDays: 0,
    ),
  ];

  static final List<AttendanceEntry> attendance = <AttendanceEntry>[
    // Demo Approver — full week of closed entries leading up to today.
    AttendanceEntry(
      id: 'att-001',
      employeeId: 'emp-001',
      date: DateTime.utc(2026, 5, 11),
      clockIn: DateTime.utc(2026, 5, 11, 8, 5),
      clockOut: DateTime.utc(2026, 5, 11, 17, 30),
    ),
    AttendanceEntry(
      id: 'att-002',
      employeeId: 'emp-001',
      date: DateTime.utc(2026, 5, 12),
      clockIn: DateTime.utc(2026, 5, 12, 7, 55),
      clockOut: DateTime.utc(2026, 5, 12, 18, 10),
      note: 'Late stand-up with engineering',
    ),
    AttendanceEntry(
      id: 'att-003',
      employeeId: 'emp-001',
      date: DateTime.utc(2026, 5, 13),
      clockIn: DateTime.utc(2026, 5, 13, 8, 0),
      clockOut: DateTime.utc(2026, 5, 13, 17, 45),
    ),
    AttendanceEntry(
      id: 'att-004',
      employeeId: 'emp-004',
      date: DateTime.utc(2026, 5, 13),
      clockIn: DateTime.utc(2026, 5, 13, 8, 30),
      clockOut: DateTime.utc(2026, 5, 13, 17, 0),
    ),
  ];

  static final List<Payslip> payslips = <Payslip>[
    Payslip(
      id: 'ps-001',
      employeeId: 'emp-001',
      employeeName: 'Demo Approver',
      periodStart: DateTime.utc(2026, 4, 1),
      periodEnd: DateTime.utc(2026, 4, 30),
      issuedAt: DateTime.utc(2026, 5, 1, 9, 0),
      grossPay: r'$4,600.00',
      totalDeductions: r'$732.00',
      netPay: r'$3,868.00',
      lineItems: const [
        PayslipLine(
          id: 'ps-001-l1',
          label: 'Base salary',
          kind: PayslipLineKind.earning,
          amount: r'$4,200.00',
        ),
        PayslipLine(
          id: 'ps-001-l2',
          label: 'Overtime — 5h @ 1.5x',
          kind: PayslipLineKind.overtime,
          amount: r'$400.00',
        ),
        PayslipLine(
          id: 'ps-001-l3',
          label: 'NSSF contribution',
          kind: PayslipLineKind.deduction,
          amount: r'$32.00',
        ),
        PayslipLine(
          id: 'ps-001-l4',
          label: 'Income tax',
          kind: PayslipLineKind.tax,
          amount: r'$700.00',
        ),
      ],
    ),
    Payslip(
      id: 'ps-002',
      employeeId: 'emp-001',
      employeeName: 'Demo Approver',
      periodStart: DateTime.utc(2026, 3, 1),
      periodEnd: DateTime.utc(2026, 3, 31),
      issuedAt: DateTime.utc(2026, 4, 1, 9, 0),
      grossPay: r'$4,200.00',
      totalDeductions: r'$682.00',
      netPay: r'$3,518.00',
      lineItems: const [
        PayslipLine(
          id: 'ps-002-l1',
          label: 'Base salary',
          kind: PayslipLineKind.earning,
          amount: r'$4,200.00',
        ),
        PayslipLine(
          id: 'ps-002-l2',
          label: 'NSSF contribution',
          kind: PayslipLineKind.deduction,
          amount: r'$32.00',
        ),
        PayslipLine(
          id: 'ps-002-l3',
          label: 'Income tax',
          kind: PayslipLineKind.tax,
          amount: r'$650.00',
        ),
      ],
    ),
    Payslip(
      id: 'ps-003',
      employeeId: 'emp-004',
      employeeName: 'Dara Nuon',
      periodStart: DateTime.utc(2026, 4, 1),
      periodEnd: DateTime.utc(2026, 4, 30),
      issuedAt: DateTime.utc(2026, 5, 1, 9, 0),
      grossPay: r'$1,500.00',
      totalDeductions: r'$172.00',
      netPay: r'$1,328.00',
      lineItems: const [
        PayslipLine(
          id: 'ps-003-l1',
          label: 'Base salary',
          kind: PayslipLineKind.earning,
          amount: r'$1,400.00',
        ),
        PayslipLine(
          id: 'ps-003-l2',
          label: 'Overtime — 4h',
          kind: PayslipLineKind.overtime,
          amount: r'$100.00',
        ),
        PayslipLine(
          id: 'ps-003-l3',
          label: 'NSSF contribution',
          kind: PayslipLineKind.deduction,
          amount: r'$22.00',
        ),
        PayslipLine(
          id: 'ps-003-l4',
          label: 'Income tax',
          kind: PayslipLineKind.tax,
          amount: r'$150.00',
        ),
      ],
    ),
  ];
}
