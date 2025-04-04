enum OrderStatusType {
  created,
  packerAssigned,
  picked,
  completed,
  cancelled,
  billing;

  @override
  String toString() {
    switch (this) {
      case OrderStatusType.created:
        return 'created';
      case OrderStatusType.packerAssigned:
        return 'packer assigned';
      case OrderStatusType.picked:
        return 'picked';
      case OrderStatusType.completed:
        return 'completed';
      case OrderStatusType.cancelled:
        return 'cancelled';
      case OrderStatusType.billing:
        return 'billing';
      // Default to 'created' if the value is not recognized
    }
  }
}

extension StatusTypeExtension on OrderStatusType {
  String toOrderStatus() {
    switch (this) {
      case OrderStatusType.created:
        return "Order Created";
      case OrderStatusType.packerAssigned:
        return "Packer Assigned";
      case OrderStatusType.picked:
        return "On The Way";
      case OrderStatusType.completed:
        return "Arrived";
      case OrderStatusType.cancelled:
        return "Cancelled";
      case OrderStatusType.billing:
        return "Billed";
    }
  }

  String toStringConversion() {
    switch (this) {
      case OrderStatusType.created:
        return "Created";
      case OrderStatusType.packerAssigned:
        return "packer Assigned";
      case OrderStatusType.picked:
        return "Delivering";
      case OrderStatusType.completed:
        return "Completed";
      case OrderStatusType.cancelled:
        return "Cancelled";
      case OrderStatusType.billing:
        return "Billed";
    }
  }

  static OrderStatusType fromString(String status) {
    switch (status) {
      case 'created':
        return OrderStatusType.created;
      case 'packer_assigned':
        return OrderStatusType.packerAssigned;
      case 'picked':
        return OrderStatusType.picked;
      case 'completed':
        return OrderStatusType.completed;
      case 'cancelled':
        return OrderStatusType.cancelled;
      case 'billing':
        return OrderStatusType.billing;
      default:
        throw ArgumentError('Unknown status type: $status');
    }
  }

  String toOrderListStatus() {
    switch (this) {
      case OrderStatusType.created:
        return "Created";
      case OrderStatusType.packerAssigned:
        return "packer_assigned";
      case OrderStatusType.picked:
        return "On The Way";
      case OrderStatusType.completed:
        return "Completed";
      case OrderStatusType.cancelled:
        return "Cancelled";
      case OrderStatusType.billing:
        return "Order Refunded";
      default:
        return "Unknown Order";
    }
  }
}
