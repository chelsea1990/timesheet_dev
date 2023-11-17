class Timesheet {
  final String id;
  final String projectName;
  final String task;
  final String dateFrom;
  final String dateTo;
  final String status;
  final String assignedTo;

  Timesheet({
    required this.id,
    this.projectName = '',
    this.task = '',
    this.dateFrom = '',
    this.dateTo = '',
    this.status = '',
    this.assignedTo = '',
  });
}