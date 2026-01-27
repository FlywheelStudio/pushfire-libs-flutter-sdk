import '../api/pushfire_api_client.dart';
import '../exceptions/pushfire_exceptions.dart';
import '../models/workflow_execution.dart';
import '../utils/logger.dart';

/// Service for managing workflow operations
class WorkflowService {
  final PushFireApiClient _apiClient;

  WorkflowService(this._apiClient);

  /// Create a workflow execution
  Future<Map<String, dynamic>> createWorkflowExecution(
    WorkflowExecutionRequest request,
  ) async {
    try {
      PushFireLogger.info('Creating workflow execution: ${request.workflowId}');

      // Validate the request
      request.validate();

      // Convert request to JSON
      final requestData = request.toJson();

      PushFireLogger.info('Workflow execution data: $requestData');

      // Make API call
      final response = await _apiClient.post(
        'create-workflow-execution',
        requestData,
      );

      PushFireLogger.info('Workflow execution created successfully');
      return response;
    } catch (e) {
      PushFireLogger.error('Workflow execution creation failed', e);
      if (e is PushFireException) {
        rethrow;
      }
      throw PushFireApiException(
        'Workflow execution creation failed: $e',
        originalError: e,
      );
    }
  }

  /// Create an immediate workflow execution for subscribers
  Future<Map<String, dynamic>> createImmediateWorkflowForSubscribers({
    required String workflowId,
    required List<String> subscriberIds,
  }) async {
    final request = WorkflowExecutionRequest(
      workflowId: workflowId,
      type: WorkflowExecutionType.immediate,
      target: WorkflowTarget(
        type: WorkflowTargetType.subscribers,
        values: subscriberIds,
      ),
    );

    return createWorkflowExecution(request);
  }

  /// Create an immediate workflow execution for segments
  Future<Map<String, dynamic>> createImmediateWorkflowForSegments({
    required String workflowId,
    required List<String> segmentIds,
  }) async {
    final request = WorkflowExecutionRequest(
      workflowId: workflowId,
      type: WorkflowExecutionType.immediate,
      target: WorkflowTarget(
        type: WorkflowTargetType.segments,
        values: segmentIds,
      ),
    );

    return createWorkflowExecution(request);
  }

  /// Create a scheduled workflow execution for subscribers
  Future<Map<String, dynamic>> createScheduledWorkflowForSubscribers({
    required String workflowId,
    required List<String> subscriberIds,
    required DateTime scheduledFor,
  }) async {
    final request = WorkflowExecutionRequest(
      workflowId: workflowId,
      type: WorkflowExecutionType.scheduled,
      scheduledFor: scheduledFor,
      target: WorkflowTarget(
        type: WorkflowTargetType.subscribers,
        values: subscriberIds,
      ),
    );

    return createWorkflowExecution(request);
  }

  /// Create a scheduled workflow execution for segments
  Future<Map<String, dynamic>> createScheduledWorkflowForSegments({
    required String workflowId,
    required List<String> segmentIds,
    required DateTime scheduledFor,
  }) async {
    final request = WorkflowExecutionRequest(
      workflowId: workflowId,
      type: WorkflowExecutionType.scheduled,
      scheduledFor: scheduledFor,
      target: WorkflowTarget(
        type: WorkflowTargetType.segments,
        values: segmentIds,
      ),
    );

    return createWorkflowExecution(request);
  }
}
