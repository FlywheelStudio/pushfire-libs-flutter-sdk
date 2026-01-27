/// Represents the type of workflow execution
enum WorkflowExecutionType {
  immediate('Immediate'),
  scheduled('Scheduled');

  const WorkflowExecutionType(this.value);
  final String value;

  static WorkflowExecutionType fromString(String value) {
    switch (value) {
      case 'Immediate':
        return WorkflowExecutionType.immediate;
      case 'Scheduled':
        return WorkflowExecutionType.scheduled;
      default:
        throw ArgumentError('Invalid WorkflowExecutionType: $value');
    }
  }
}

/// Represents the type of target for workflow execution
enum WorkflowTargetType {
  subscribers('Subscribers'),
  segments('Segments');

  const WorkflowTargetType(this.value);
  final String value;

  static WorkflowTargetType fromString(String value) {
    switch (value) {
      case 'Subscribers':
        return WorkflowTargetType.subscribers;
      case 'Segments':
        return WorkflowTargetType.segments;
      default:
        throw ArgumentError('Invalid WorkflowTargetType: $value');
    }
  }
}

/// Represents the target configuration for workflow execution
class WorkflowTarget {
  /// Type of target (Subscribers or Segments)
  final WorkflowTargetType type;

  /// Array of UUIDs for subscribers or segments
  final List<String> values;

  const WorkflowTarget({
    required this.type,
    required this.values,
  });

  /// Create a WorkflowTarget from JSON
  factory WorkflowTarget.fromJson(Map<String, dynamic> json) {
    return WorkflowTarget(
      type: WorkflowTargetType.fromString(json['type'] as String),
      values:
          (json['values'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  /// Convert WorkflowTarget to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'values': values,
    };
  }

  @override
  String toString() {
    return 'WorkflowTarget(type: ${type.value}, values: $values)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkflowTarget &&
        other.type == type &&
        _listEquals(other.values, values);
  }

  @override
  int get hashCode {
    return Object.hash(type, Object.hashAll(values));
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// Represents a workflow execution request
class WorkflowExecutionRequest {
  /// UUID of the workflow to execute
  final String workflowId;

  /// Type of workflow execution
  final WorkflowExecutionType type;

  /// ISO date string for scheduled execution (required when type is Scheduled)
  final DateTime? scheduledFor;

  /// Target configuration for the workflow execution
  final WorkflowTarget target;

  const WorkflowExecutionRequest({
    required this.workflowId,
    required this.type,
    this.scheduledFor,
    required this.target,
  });

  /// Create a WorkflowExecutionRequest from JSON
  factory WorkflowExecutionRequest.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return WorkflowExecutionRequest(
      workflowId: data['workflowId'] as String,
      type: WorkflowExecutionType.fromString(data['type'] as String),
      scheduledFor: data['scheduledFor'] != null
          ? DateTime.parse(data['scheduledFor'] as String)
          : null,
      target: WorkflowTarget.fromJson(data['target'] as Map<String, dynamic>),
    );
  }

  /// Convert WorkflowExecutionRequest to JSON
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'workflowId': workflowId,
      'type': type.value,
      'target': target.toJson(),
    };

    if (scheduledFor != null) {
      data['scheduledFor'] = scheduledFor!.toIso8601String();
    }

    return {
      'data': data,
    };
  }

  /// Validate the request
  void validate() {
    if (workflowId.isEmpty) {
      throw ArgumentError('workflowId cannot be empty');
    }

    if (type == WorkflowExecutionType.scheduled && scheduledFor == null) {
      throw ArgumentError('scheduledFor is required when type is Scheduled');
    }

    if (target.values.isEmpty) {
      throw ArgumentError('target values cannot be empty');
    }

    // Validate UUID format for workflowId
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (!uuidRegex.hasMatch(workflowId)) {
      throw ArgumentError('workflowId must be a valid UUID');
    }

    // Validate UUID format for target values
    for (final value in target.values) {
      if (!uuidRegex.hasMatch(value)) {
        throw ArgumentError('All target values must be valid UUIDs: $value');
      }
    }
  }

  @override
  String toString() {
    return 'WorkflowExecutionRequest(workflowId: $workflowId, type: ${type.value}, scheduledFor: $scheduledFor, target: $target)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkflowExecutionRequest &&
        other.workflowId == workflowId &&
        other.type == type &&
        other.scheduledFor == scheduledFor &&
        other.target == target;
  }

  @override
  int get hashCode {
    return Object.hash(
      workflowId,
      type,
      scheduledFor,
      target,
    );
  }
}
