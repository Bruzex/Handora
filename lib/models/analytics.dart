class DayEarning {
  final String dayEn;
  final String dayHi;
  final double amount;

  const DayEarning(this.dayEn, this.dayHi, this.amount);
}

const kWeekEarnings = <DayEarning>[
  DayEarning('Mon', 'सोम', 4200),
  DayEarning('Tue', 'मंगल', 5100),
  DayEarning('Wed', 'बुध', 4800),
  DayEarning('Thu', 'गुरु', 7300),
  DayEarning('Fri', 'शुक्र', 6400),
  DayEarning('Sat', 'शनि', 11200),
  DayEarning('Sun', 'रवि', 6500),
];

// Find the day with highest earnings for the peak marker on the chart.
final kPeakDay = kWeekEarnings.reduce(
  (best, d) => d.amount > best.amount ? d : best,
);

class Revenue {
  final String total;
  final String trend;
  final String totalOrders;
  final String avgOrderValue;

  const Revenue({
    required this.total,
    required this.trend,
    required this.totalOrders,
    required this.avgOrderValue,
  });
}

const kRevenue = Revenue(
  total: '₹45,500',
  trend: '+18.4%',
  totalOrders: '128',
  avgOrderValue: '₹355',
);
