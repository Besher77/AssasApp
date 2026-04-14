/// Snapshot for the admin home dashboard (counts + revenue estimate).
class AdminDashboardStats {
  const AdminDashboardStats({
    required this.clientsCount,
    required this.engineersCount,
    required this.adminsCount,
    required this.projectsTotal,
    required this.projectsNew,
    required this.projectsInProgress,
    required this.projectsDelivered,
    required this.projectsCompleted,
    required this.projectsCancelled,
    required this.completedProjectsPaidTotalSar,
    required this.estimatedPlatformFeesSar,
  });

  /// Same rate as in-app copy: 10% platform fee on completed project payments.
  static const double platformFeeRate = 0.1;

  final int clientsCount;
  final int engineersCount;
  final int adminsCount;

  final int projectsTotal;
  final int projectsNew;
  final int projectsInProgress;
  final int projectsDelivered;
  final int projectsCompleted;
  final int projectsCancelled;

  /// Sum of `paidAmount` on projects with status `completed` (ignores null / non-positive).
  final double completedProjectsPaidTotalSar;

  /// [completedProjectsPaidTotalSar] × [platformFeeRate].
  final double estimatedPlatformFeesSar;

  int get totalUserAccounts => clientsCount + engineersCount + adminsCount;

  int get projectsActive => projectsInProgress + projectsDelivered;
}
