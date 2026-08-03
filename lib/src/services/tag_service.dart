import '../api/pushfire_api_client.dart';
import '../exceptions/pushfire_exceptions.dart';
import '../models/subscriber_tag.dart';
import '../utils/logger.dart';
import 'subscriber_service.dart';

/// Service for managing subscriber tags
class TagService {
  final PushFireApiClient _apiClient;
  final SubscriberService _subscriberService;

  TagService(this._apiClient, this._subscriberService);

  /// Add a tag to the current subscriber
  Future<SubscriberTag> addTag(String tagId, String value) async {
    try {
      // Value omitted: tag values routinely hold an email, plan or region.
      PushFireLogger.info('Adding tag: $tagId');

      // Get current subscriber ID
      final subscriberId = await _subscriberService.getSubscriberId();
      if (subscriberId == null) {
        throw const PushFireTagException(
          'No subscriber logged in. Call loginSubscriber() first.',
        );
      }

      // Create tag data
      final tagData = {
        'data': {
          'tagId': tagId,
          'subscriberId': subscriberId,
          'value': value,
        },
      };

      // Make API call
      await _apiClient.post('add-subscriber-tag', tagData);

      // Create tag object
      final tag = SubscriberTag(
        tagId: tagId,
        subscriberId: subscriberId,
        value: value,
      );

      PushFireLogger.info('Tag added successfully: $tagId');
      return tag;
    } on PushFireException {
      rethrow;
    } catch (e) {
      PushFireLogger.error('Unexpected error adding tag', e);
      throw PushFireTagException(
        'Failed to add tag: $e',
        originalError: e,
      );
    }
  }

  /// Update a tag value for the current subscriber
  Future<SubscriberTag> updateTag(String tagId, String value) async {
    try {
      PushFireLogger.info('Updating tag: $tagId');

      // Get current subscriber ID
      final subscriberId = await _subscriberService.getSubscriberId();
      if (subscriberId == null) {
        throw const PushFireTagException(
          'No subscriber logged in. Call loginSubscriber() first.',
        );
      }

      // Create tag data
      final tagData = {
        'data': {
          'tagId': tagId,
          'subscriberId': subscriberId,
          'value': value,
        },
      };

      // Make API call
      await _apiClient.patch('update-subscriber-tag', tagData);

      // Create tag object
      final tag = SubscriberTag(
        tagId: tagId,
        subscriberId: subscriberId,
        value: value,
      );

      PushFireLogger.info('Tag updated successfully: $tagId');
      return tag;
    } on PushFireException {
      rethrow;
    } catch (e) {
      PushFireLogger.error('Unexpected error updating tag', e);
      throw PushFireTagException(
        'Failed to update tag: $e',
        originalError: e,
      );
    }
  }

  /// Remove a tag from the current subscriber
  Future<void> removeTag(String tagId) async {
    try {
      PushFireLogger.info('Removing tag: $tagId');

      // Get current subscriber ID
      final subscriberId = await _subscriberService.getSubscriberId();
      if (subscriberId == null) {
        throw const PushFireTagException(
          'No subscriber logged in. Call loginSubscriber() first.',
        );
      }

      // Create tag data
      final tagData = {
        'data': {
          'tagId': tagId,
          'subscriberId': subscriberId,
        },
      };

      // Make API call
      await _apiClient.delete('remove-subscriber-tag', tagData);

      PushFireLogger.info('Tag removed successfully: $tagId');
    } on PushFireException {
      rethrow;
    } catch (e) {
      PushFireLogger.error('Unexpected error removing tag', e);
      throw PushFireTagException(
        'Failed to remove tag: $e',
        originalError: e,
      );
    }
  }

  /// Add multiple tags at once
  Future<List<SubscriberTag>> addTags(Map<String, String> tags) async {
    final results = <SubscriberTag>[];
    final errors = <String, dynamic>{};

    for (final entry in tags.entries) {
      try {
        final tag = await addTag(entry.key, entry.value);
        results.add(tag);
      } catch (e) {
        errors[entry.key] = e;
        PushFireLogger.warning('Failed to add tag ${entry.key}: $e');
      }
    }

    if (errors.isNotEmpty && results.isEmpty) {
      throw PushFireTagException(
        'Failed to add all tags: ${errors.keys.join(", ")}',
      );
    }

    if (errors.isNotEmpty) {
      PushFireLogger.warning(
        'Some tags failed to add: ${errors.keys.join(", ")}',
      );
    }

    return results;
  }

  /// Update multiple tags at once
  Future<List<SubscriberTag>> updateTags(Map<String, String> tags) async {
    final results = <SubscriberTag>[];
    final errors = <String, dynamic>{};

    for (final entry in tags.entries) {
      try {
        final tag = await updateTag(entry.key, entry.value);
        results.add(tag);
      } catch (e) {
        errors[entry.key] = e;
        PushFireLogger.warning('Failed to update tag ${entry.key}: $e');
      }
    }

    if (errors.isNotEmpty && results.isEmpty) {
      throw PushFireTagException(
        'Failed to update all tags: ${errors.keys.join(", ")}',
      );
    }

    if (errors.isNotEmpty) {
      PushFireLogger.warning(
        'Some tags failed to update: ${errors.keys.join(", ")}',
      );
    }

    return results;
  }

  /// Remove multiple tags at once
  Future<void> removeTags(List<String> tagIds) async {
    final errors = <String, dynamic>{};

    for (final tagId in tagIds) {
      try {
        await removeTag(tagId);
      } catch (e) {
        errors[tagId] = e;
        PushFireLogger.warning('Failed to remove tag $tagId: $e');
      }
    }

    if (errors.isNotEmpty) {
      if (errors.length == tagIds.length) {
        throw PushFireTagException(
          'Failed to remove all tags: ${errors.keys.join(", ")}',
        );
      } else {
        PushFireLogger.warning(
          'Some tags failed to remove: ${errors.keys.join(", ")}',
        );
      }
    }
  }
}
