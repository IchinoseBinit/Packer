class LeaveRequest {
  int? id;
  Employee? employee;
  String? startDate;
  String? endDate;
  String? reason;
  String? status;
  Employee? approvedBy;
  DateTime? approvedAt;
  String? createdAt;
  String? updatedAt;

  LeaveRequest({
    this.id,
    this.employee,
    this.startDate,
    this.endDate,
    this.reason,
    this.status,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
  });

  LeaveRequest.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    employee =
        json['employee'] != null ? Employee.fromJson(json['employee']) : null;
    startDate = json['start_date'];
    endDate = json['end_date'];
    reason = json['reason'];
    status = json['status'];
    approvedBy = json['approved_by'];
    approvedAt = json['approved_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (employee != null) {
      data['employee'] = employee!.toJson();
    }
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['reason'] = reason;
    data['status'] = status;
    data['approved_by'] = approvedBy;
    data['approved_at'] = approvedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Employee {
  int? id;
  String? name;

  Employee({this.id, this.name});

  Employee.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}
