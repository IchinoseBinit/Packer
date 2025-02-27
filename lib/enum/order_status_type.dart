enum OrderStatusType {
  created,
  acknowledged,
  picked,
  completed,
  cancelled,
  refunds;

  @override
  String toString() {
    switch (this) {
      case OrderStatusType.created:
        return 'created';
      case OrderStatusType.acknowledged:
        return 'acknowledged';
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
      case OrderStatusType.acknowledged:
        return "Packed";
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
      case OrderStatusType.acknowledged:
        return "Acknowledged";
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
      case 'acknowledged':
        return OrderStatusType.acknowledged;
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
      case OrderStatusType.acknowledged:
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
