/// EventActionDialog - Event Details & Actions View
/// 
/// Full-screen dialog displaying detailed event information with action buttons.
/// 
/// Features:
/// - Event title, classification, and priority display
/// - Date, time, and location information
/// - Notes and voice note attachments
/// - Mark as complete/incomplete
/// - Edit event details
/// - Delete event
/// - Quick action buttons (add to calendar, set reminders)
/// - Visual categorization with color coding
/// - Attendance tracking for timetable-based classes
/// 
/// Changes are persisted to DataProvider and reflected across all views.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';
import '../backend/timetable_models.dart';
import 'theme.dart';
import 'add_event_dialog.dart';
import 'gamification_popup.dart';
import 'streak_tier_popup.dart';

class EventActionDialog extends StatefulWidget {
  final Event event;

  const EventActionDialog({
    super.key,
    required this.event,
  });

  @override
  State<EventActionDialog> createState() => _EventActionDialogState();
}

class _EventActionDialogState extends State<EventActionDialog> {
  late Event currentEvent;

  @override
  void initState() {
    super.initState();
    currentEvent = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        // Get the latest event from provider
        final freshEvent = dataProvider.events.firstWhere(
          (e) => e.id == currentEvent.id,
          orElse: () => currentEvent,
        );
        currentEvent = freshEvent;

        final color = freshEvent.completionColor != null
            ? Color(int.parse(freshEvent.completionColor!.replaceFirst('#', '0xFF')))
            : AppTheme.getClassificationColor(freshEvent.classification);

        return _buildDialog(context, freshEvent, color);
      },
    );
  }

  bool get _isClassEvent => currentEvent.classification == 'class';

  Widget _buildDialog(BuildContext context, Event event, Color color) {
    // Const SizedBox instances to avoid repeated allocation
    const sizedBoxWidth16 = SizedBox(width: 16);
    final c05 = color.withValues(alpha: 0.05);
    final c1 = color.withValues(alpha: 0.1);
    final c15 = color.withValues(alpha: 0.15);
    final c3 = color.withValues(alpha: 0.3);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c15, c05],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: c3,
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          AppTheme.getClassificationIcon(event.classification),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      sizedBoxWidth16,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM d, h:mm a').format(event.startTime),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: color),
                        style: IconButton.styleFrom(
                          backgroundColor: c1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable details section
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Details Section
                          _buildDetailItem(
                            context,
                            icon: Icons.calendar_today,
                            label: 'Date & Time',
                            value: _formatDateTime(),
                            color: color,
                          ),
                          const SizedBox(height: 12),

                          if (event.endTime != null) ...[  
                            _buildDetailItem(
                              context,
                              icon: Icons.timelapse,
                              label: 'Duration',
                              value: _formatEventDuration(),
                              color: color,
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (event.location != null && event.location!.isNotEmpty) ...[
                            _buildDetailItem(
                              context,
                              icon: Icons.location_on,
                              label: 'Location',
                              value: event.location!,
                              color: color,
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (event.category != null && event.category!.isNotEmpty) ...[
                            _buildDetailItem(
                              context,
                              icon: Icons.category,
                              label: 'Category',
                              value: event.category!,
                              color: color,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Inline details row
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactDetailItem(
                                  context,
                                  icon: Icons.label,
                                  label: 'Type',
                                  value: _formatClassification(event.classification),
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCompactDetailItem(
                                  context,
                                  icon: Icons.priority_high,
                                  label: 'Priority',
                                  value: _formatPriority(event.priority),
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_isClassEvent && event.periodCount > 1) ...[
                            _buildCompactDetailItem(
                              context,
                              icon: Icons.repeat,
                              label: 'Periods Count',
                              value: event.periodCount.toString(),
                              color: color,
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (event.estimatedDuration != null && event.estimatedDuration!.isNotEmpty) ...[
                            _buildDetailItem(
                              context,
                              icon: Icons.hourglass_empty,
                              label: 'Estimated Duration',
                              value: event.estimatedDuration!,
                              color: color,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Status badges
                          if (event.isImportant || event.isCompleted)
                            _buildStatusBadges(context, color, event),

                          // Notes section
                          if (event.notes != null && event.notes!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildSectionHeader(context, 'Notes', color),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                event.notes!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                          // Voice notes section
                          if (event.voiceNotes.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildSectionHeader(context, 'Voice Notes (${event.voiceNotes.length})', color),
                            const SizedBox(height: 12),
                            ...event.voiceNotes.asMap().entries.map((entry) =>
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key == event.voiceNotes.length - 1 ? 0 : 10,
                                ),
                                child: _buildVoiceNoteItem(context, entry.value, color),
                              ),
                            ).toList(),
                          ],

                          // Attachments section
                          if (event.attachments.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildSectionHeader(context, 'Attachments (${event.attachments.length})', color),
                            const SizedBox(height: 12),
                            ...event.attachments.asMap().entries.map((entry) =>
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key == event.attachments.length - 1 ? 0 : 10,
                                ),
                                child: _buildAttachmentItem(context, entry.value, entry.key, color),
                              ),
                            ).toList(),
                          ],

                          // Reminders section
                          if (event.reminders.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _buildSectionHeader(context, 'Reminders (${event.reminders.length})', color),
                            const SizedBox(height: 12),
                            ...event.reminders.asMap().entries.map((entry) =>
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key == event.reminders.length - 1 ? 0 : 10,
                                ),
                                child: _buildReminderItem(context, entry.value, color),
                              ),
                            ).toList(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Divider
            Container(
              height: 1,
              color: Colors.grey.withValues(alpha: 0.2),
            ),

            // Actions at bottom
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_isClassEvent)
                    _buildClassActions(context, color, event)
                  else
                    _buildRegularEventActions(context, color, event),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadges(BuildContext context, Color color, Event event) {
    final badges = <Widget>[];

    if (event.isImportant) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.warningAmber.withValues(alpha: 0.2),
                AppTheme.warningAmber.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.warningAmber.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: AppTheme.warningAmber, size: 16),
              const SizedBox(width: 6),
              Text(
                'Important',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.warningAmber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (event.isCompleted) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.successGreen.withValues(alpha: 0.2),
                AppTheme.successGreen.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.successGreen.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: AppTheme.successGreen, size: 16),
              const SizedBox(width: 6),
              Text(
                'Completed',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.successGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (event.isMissed) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.errorRed.withValues(alpha: 0.2),
                AppTheme.errorRed.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.errorRed.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel, color: AppTheme.errorRed, size: 16),
              const SizedBox(width: 6),
              Text(
                'Missed',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (event.isCancelled) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.otherGray.withValues(alpha: 0.2),
                AppTheme.otherGray.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.otherGray.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_flipped, color: AppTheme.otherGray, size: 16),
              const SizedBox(width: 6),
              Text(
                'Cancelled',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.otherGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        children: badges,
      ),
    );
  }

  String _formatEventDuration() {
    if (currentEvent.endTime == null) return '';
    final diff = currentEvent.endTime!.difference(currentEvent.startTime);
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days day${days > 1 ? 's' : ''}');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}min');
    return parts.isEmpty ? '0 min' : parts.join(' ');
  }

  String _formatDateTime() {
    if (currentEvent.endTime != null) {
      final startStr = DateFormat('MMM d, h:mm a').format(currentEvent.startTime);
      final endStr = DateFormat('h:mm a').format(currentEvent.endTime!);
      return '$startStr - $endStr';
    }
    return DateFormat('MMM d, h:mm a').format(currentEvent.startTime);
  }

  String _formatClassification(String classification) {
    return classification[0].toUpperCase() + classification.substring(1).replaceAll('_', ' ');
  }

  String _formatPriority(String priority) {
    return priority[0].toUpperCase() + priority.substring(1);
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).textTheme.labelSmall?.color?.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).textTheme.labelSmall?.color?.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceNoteItem(BuildContext context, VoiceNote voiceNote, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  try {
                    final audioPlayer = AudioPlayer();
                    await audioPlayer.play(DeviceFileSource(voiceNote.filePath));
                  } catch (e) {
                    debugPrint('Error playing voice note: $e');
                  }
                },
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice Note',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${voiceNote.duration.inSeconds}s • ${DateFormat('MMM d, h:mm a').format(voiceNote.recordedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                    fontSize: 11,
                  ),
                ),
                if (voiceNote.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: voiceNote.tags.map((tag) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem(BuildContext context, String attachment, int index, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.attach_file, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attachment ${index + 1}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  attachment,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderItem(BuildContext context, DateTime reminder, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.notifications_active, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, h:mm a').format(reminder),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildClassActions(BuildContext context, Color color, Event event) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final attendance = dataProvider.getAttendanceForDate(
      event.title,
      event.startTime,
    );

    final bool isMarked = attendance != null;

    return Column(
      children: [
        // Main action button - Mark or Unmark
        SizedBox(
          width: double.infinity,
          height: 56,
          child: isMarked
              ? FilledButton.icon(
                  onPressed: () {
                    _unmarkAttendance(context, event);
                  },
                  icon: const Icon(Icons.clear_outlined),
                  label: const Text('Unmark Attendance'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              : FilledButton.icon(
                  onPressed: () {
                    _showMarkAttendanceDialog(context, color);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Attendance'),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // Edit details button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AddEventDialog(editEvent: event),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Details'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showMarkAttendanceDialog(BuildContext context, Color color) {
    final allowedStatuses = [
      AttendanceStatus.present,
      AttendanceStatus.absent,
      AttendanceStatus.cancelled,
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_turned_in_outlined,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark Attendance',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.event.title,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.1),
                      foregroundColor: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Attendance status options
              ...allowedStatuses.map((status) {
                final statusColor = _getAttendanceColor(status);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(dialogContext);
                      _markAttendance(context, status);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getAttendanceIcon(status),
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getAttendanceLabel(status),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getAttendanceDescription(status),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegularEventActions(BuildContext context, Color color, Event event) {
    final isCompleted = event.isCompleted;
    final isMissed = event.isMissed;
    final isCancelled = event.isCancelled;
    final hasStatus = isCompleted || isMissed || isCancelled;

    return Column(
      children: [
        // Mark Status button - Direct unmark on tap when marked
        SizedBox(
          width: double.infinity,
          height: 56,
          child: hasStatus
              ? FilledButton.icon(
                  onPressed: () {
                    _clearEventStatus(context);
                  },
                  icon: const Icon(Icons.clear_outlined),
                  label: const Text('Clear Status'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              : FilledButton.icon(
                  onPressed: () {
                    _showStatusDialog(context, color);
                  },
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Mark Status'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // Edit button with consistent border
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AddEventDialog(editEvent: widget.event),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Event'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _unmarkAttendance(BuildContext context, Event event) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    // Find and delete the attendance record
    final attendance = dataProvider.getAttendanceForDate(
      event.title,
      event.startTime,
    );
    
    if (attendance != null) {
      // Delete attendance record
      dataProvider.deleteAttendanceRecord(attendance.id);
      
      // Reset event completion
      widget.event.completionColor = null;
      widget.event.isCompleted = false;
      widget.event.isMissed = false;
      widget.event.isCancelled = false;
      
      // Update the event in the provider
      dataProvider.updateEvent(widget.event);
      
      Navigator.pop(context);
      
      AppTheme.showTopNotification(
        context,
        'Attendance has been cleared for this class.',
        type: NotificationType.warning,
      );
    }
  }

  void _markAttendance(BuildContext context, AttendanceStatus status) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    final recordId = const Uuid().v4();
    final record = AttendanceRecord(
      id: recordId,
      courseName: widget.event.title,
      date: widget.event.startTime,
      status: status,
      periodCount: widget.event.periodCount,
    );
    
    dataProvider.markAttendance(record);
    
    // Update event completion color and status based on attendance
    widget.event.completionColor = '#${_getAttendanceColor(status).toARGB32().toRadixString(16).substring(2)}';
    widget.event.isCompleted = true; 
    dataProvider.updateEvent(widget.event);
    
    // Show gamification popup BEFORE popping so context remains valid
    final now = DateTime.now();
    final isToday = widget.event.startTime.year == now.year &&
                    widget.event.startTime.month == now.month &&
                    widget.event.startTime.day == now.day;
    if (mounted) Navigator.pop(context);
    if (!context.mounted) return;
    final bool gameEnabled = dataProvider.gamificationEnabled;
    final bool notMuted = !dataProvider.muteRingtone;
    if (gameEnabled && isToday) {
      await GamificationPopupService.showEventStatusPopup(
        context,
        widget.event.title,
        status.name == 'present' ? 'present' : status.name == 'absent' ? 'absent' : 'cancelled',
      );
    } else if (notMuted) {
      GamificationPopupService.audioPlayer
          .stop()
          .then((_) => GamificationPopupService.audioPlayer.play(AssetSource('accept2.mp3')));
    }
  }

  Color _getAttendanceColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppTheme.successGreen;
      case AttendanceStatus.absent:
        return AppTheme.errorRed;
      case AttendanceStatus.late:
        return AppTheme.warningAmber;
      case AttendanceStatus.excused:
        return AppTheme.secondaryTeal;
      case AttendanceStatus.cancelled:
        return AppTheme.otherGray;
    }
  }

  IconData _getAttendanceIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.excused:
        return Icons.event_busy;
      case AttendanceStatus.cancelled:
        return Icons.block;
    }
  }

  void _showStatusDialog(BuildContext context, Color color) {
    final statuses = [
      {'status': 'completed', 'label': 'Completed', 'description': 'Event completed successfully', 'color': AppTheme.successGreen},
      {'status': 'missed', 'label': 'Missed', 'description': 'Event was missed', 'color': AppTheme.errorRed},
      {'status': 'cancelled', 'label': 'Cancelled', 'description': 'Event was cancelled', 'color': AppTheme.otherGray},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flag_outlined,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark Event Status',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.event.title,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.1),
                      foregroundColor: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Status options
              ...statuses.map((statusInfo) {
                final statusColor = statusInfo['color'] as Color;
                final statusLabel = statusInfo['label'] as String;
                final statusDescription = statusInfo['description'] as String;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(dialogContext);
                      if (statusInfo['status'] == 'completed') {
                        _markEventAsCompleted(context);
                      } else if (statusInfo['status'] == 'missed') {
                        _markEventAsMissed(context);
                      } else if (statusInfo['status'] == 'cancelled') {
                        _markEventAsCancelled(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              statusInfo['status'] == 'completed' 
                                ? Icons.check_circle 
                                : statusInfo['status'] == 'missed'
                                ? Icons.cancel
                                : Icons.block_flipped,
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  statusDescription,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markEventAsCompleted(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    widget.event.isCompleted = true;
    widget.event.isMissed = false;
    widget.event.isCancelled = false;
    dataProvider.updateEvent(widget.event);
    final oldTier = StreakService.getTierIndex(dataProvider.streakCount);
    dataProvider.incrementStreak();
    final newTier = StreakService.getTierIndex(dataProvider.streakCount);
    final bool rankChanged = newTier != oldTier;
    final now = DateTime.now();
    final bool isToday = widget.event.startTime.year == now.year &&
                         widget.event.startTime.month == now.month &&
                         widget.event.startTime.day == now.day;
    if (mounted) Navigator.pop(context);
    if (!context.mounted) return;
    final bool gameEnabled = dataProvider.gamificationEnabled;
    final bool notMuted = !dataProvider.muteRingtone;
    if (gameEnabled) {
      if (isToday && !rankChanged) {
        // game popup + accept2 (popup handles sound internally)
        await GamificationPopupService.showEventStatusPopup(context, widget.event.title, 'completed');
      } else if (!isToday && !rankChanged) {
        // no popup, just accept2
        if (notMuted) {
          GamificationPopupService.audioPlayer
              .stop()
              .then((_) => GamificationPopupService.audioPlayer.play(AssetSource('accept2.mp3')));
        }
      } else if (isToday && rankChanged) {
        // game popup + accept2, then planet popup + win.mp3
        await GamificationPopupService.showEventStatusPopup(context, widget.event.title, 'completed');
        if (context.mounted) {
          await StreakTierPopupService.showTierChange(
            context,
            oldTier: oldTier,
            newTier: newTier,
            muteRingtone: dataProvider.muteRingtone,
            streakCount: dataProvider.streakCount,
          );
        }
      } else {
        // other day + rank changed: only planet popup + win.mp3
        if (context.mounted) {
          await StreakTierPopupService.showTierChange(
            context,
            oldTier: oldTier,
            newTier: newTier,
            muteRingtone: dataProvider.muteRingtone,
            streakCount: dataProvider.streakCount,
          );
        }
      }
    } else {
      if (!rankChanged) {
        // just accept2 (all days)
        if (notMuted) {
          GamificationPopupService.audioPlayer
              .stop()
              .then((_) => GamificationPopupService.audioPlayer.play(AssetSource('accept2.mp3')));
        }
      } else {
        // planet popup + win.mp3 (all days)
        if (context.mounted) {
          await StreakTierPopupService.showTierChange(
            context,
            oldTier: oldTier,
            newTier: newTier,
            muteRingtone: dataProvider.muteRingtone,
            streakCount: dataProvider.streakCount,
          );
        }
      }
    }
  }

  Future<void> _markEventAsMissed(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    widget.event.isCompleted = false;
    widget.event.isMissed = true;
    widget.event.isCancelled = false;
    dataProvider.updateEvent(widget.event);
    final oldTier = StreakService.getTierIndex(dataProvider.streakCount);
    dataProvider.applyMissedPenalty();
    final newTier = StreakService.getTierIndex(dataProvider.streakCount);
    final bool rankChanged = newTier != oldTier;
    final now = DateTime.now();
    final bool isToday = widget.event.startTime.year == now.year &&
                         widget.event.startTime.month == now.month &&
                         widget.event.startTime.day == now.day;
    if (mounted) Navigator.pop(context);
    if (!context.mounted) return;
    final bool gameEnabled = dataProvider.gamificationEnabled;
    final bool notMuted = !dataProvider.muteRingtone;
    if (gameEnabled) {
      if (isToday && !rankChanged) {
        await GamificationPopupService.showEventStatusPopup(context, widget.event.title, 'missed');
      } else if (!isToday && !rankChanged) {
        if (notMuted) {
          GamificationPopupService.audioPlayer
              .stop()
              .then((_) => GamificationPopupService.audioPlayer.play(AssetSource('accept2.mp3')));
        }
      } else if (isToday && rankChanged) {
        await GamificationPopupService.showEventStatusPopup(context, widget.event.title, 'missed');
        if (context.mounted) {
          await StreakTierPopupService.showTierChange(
            context,
            oldTier: oldTier,
            newTier: newTier,
            muteRingtone: dataProvider.muteRingtone,
            streakCount: dataProvider.streakCount,
          );
        }
      } else {
        if (context.mounted) {
          await StreakTierPopupService.showTierChange(
            context,
            oldTier: oldTier,
            newTier: newTier,
            muteRingtone: dataProvider.muteRingtone,
            streakCount: dataProvider.streakCount,
          );
        }
      }
    } else {
      if (!rankChanged) {
        if (notMuted) {
          GamificationPopupService.audioPlayer
              .stop()
              .then((_) => GamificationPopupService.audioPlayer.play(AssetSource('accept2.mp3')));
        }
      } else {
        if (context.mounted) {
          await StreakTierPopupService.showTierChange(
            context,
            oldTier: oldTier,
            newTier: newTier,
            muteRingtone: dataProvider.muteRingtone,
            streakCount: dataProvider.streakCount,
          );
        }
      }
    }
  }

  Future<void> _markEventAsCancelled(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    widget.event.isCompleted = false;
    widget.event.isMissed = false;
    widget.event.isCancelled = true;
    dataProvider.updateEvent(widget.event);
    final now = DateTime.now();
    final bool isToday = widget.event.startTime.year == now.year &&
                         widget.event.startTime.month == now.month &&
                         widget.event.startTime.day == now.day;
    if (mounted) Navigator.pop(context);
    if (!context.mounted) return;
    final bool gameEnabled = dataProvider.gamificationEnabled;
    final bool notMuted = !dataProvider.muteRingtone;
    if (gameEnabled && isToday) {
      await GamificationPopupService.showEventStatusPopup(context, widget.event.title, 'cancelled');
    } else if (notMuted) {
      GamificationPopupService.audioPlayer
          .stop()
          .then((_) => GamificationPopupService.audioPlayer.play(AssetSource('accept2.mp3')));
    }
  }

  Future<void> _clearEventStatus(BuildContext context) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    // Reverse streak effect of the previous status (non-class events only)
    if (!_isClassEvent) {
      final oldTier = StreakService.getTierIndex(dataProvider.streakCount);
      if (widget.event.isCompleted) {
        // Revert the +1 earned for completion (no penalty, just undo)
        dataProvider.softDecrementStreak();
      } else if (widget.event.isMissed) {
        // Revert the −5 penalty that was applied when missed
        dataProvider.reverseMissedPenalty();
      }
      final newTier = StreakService.getTierIndex(dataProvider.streakCount);

      widget.event.isCompleted = false;
      widget.event.isMissed = false;
      widget.event.isCancelled = false;
      dataProvider.updateEvent(widget.event);

      Navigator.pop(context);
      AppTheme.showTopNotification(
        context,
        'Event status cleared.',
        type: NotificationType.info,
      );

      // Show planet rank popup if rank changed
      if (newTier != oldTier && context.mounted) {
        await StreakTierPopupService.showTierChange(
          context,
          oldTier: oldTier,
          newTier: newTier,
          muteRingtone: dataProvider.muteRingtone,
          streakCount: dataProvider.streakCount,
        );
      }
    } else {
      widget.event.isCompleted = false;
      widget.event.isMissed = false;
      widget.event.isCancelled = false;
      dataProvider.updateEvent(widget.event);

      Navigator.pop(context);
      AppTheme.showTopNotification(
        context,
        'Event status cleared.',
        type: NotificationType.info,
      );
    }
  }

  String _getAttendanceLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
      case AttendanceStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getAttendanceDescription(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Attended on time';
      case AttendanceStatus.absent:
        return 'Did not attend';
      case AttendanceStatus.late:
        return 'Attended late';
      case AttendanceStatus.excused:
        return 'Excused absence';
      case AttendanceStatus.cancelled:
        return 'Class was cancelled (not counted)';
    }
  }
}
