enum OrderStatusType {
  created,
  packer_assigned,
  picked,
  completed,
  cancelled,
  refunds;

  @override
  String toString() {
    switch (this) {
      case OrderStatusType.created:
        return 'created';
      case OrderStatusType.packer_assigned:
        return 'packer_assigned';
      case OrderStatusType.picked:
        return 'picked';
      case OrderStatusType.completed:
        return 'completed';
      case OrderStatusType.cancelled:
        return 'cancelled';
      case OrderStatusType.refunds:
        return 'refunds';
      default:
        return 'created'; // Default to 'created' if the value is not recognized
    }
  }
}

extension StatusTypeExtension on OrderStatusType {
  String toOrderStatus() {
    switch (this) {
      case OrderStatusType.created:
        return "Order Created";
      case OrderStatusType.packer_assigned:
        return "packer_assigned";
      case OrderStatusType.picked:
        return "On The Way";
      case OrderStatusType.completed:
        return "Arrived";
      case OrderStatusType.cancelled:
        return "Cancelled";
      case OrderStatusType.refunds:
        return "Order Refunded";
      default:
        return "Unknown Order";
    }
  }

  String toStringConversion() {
    switch (this) {
      case OrderStatusType.created:
        return "Created";
      case OrderStatusType.packer_assigned:
        return "packer_assigned";
      case OrderStatusType.picked:
        return "Delivering";
      case OrderStatusType.completed:
        return "Completed";
      case OrderStatusType.cancelled:
        return "Cancelled";
      case OrderStatusType.refunds:
        return "Order Refunded";
      default:
        return "Unknown Order";
    }
  }

  static OrderStatusType fromString(String status) {
    switch (status) {
      case 'created':
        return OrderStatusType.created;
      case 'packer_assigned':
        return OrderStatusType.packer_assigned;
      case 'picked':
        return OrderStatusType.picked;
      case 'completed':
        return OrderStatusType.completed;
      case 'cancelled':
        return OrderStatusType.cancelled;
      case 'refunds':
        return OrderStatusType.refunds;
      default:
        throw ArgumentError('Unknown status type: $status');
    }
  }

  String toOrderListStatus() {
    switch (this) {
      case OrderStatusType.created:
        return "Created";
      case OrderStatusType.packer_assigned:
        return "packer_assigned";
      case OrderStatusType.picked:
        return "On The Way";
      case OrderStatusType.completed:
        return "Completed";
      case OrderStatusType.cancelled:
        return "Cancelled";
      case OrderStatusType.refunds:
        return "Order Refunded";
      default:
        return "Unknown Order";
    }
  }
}
