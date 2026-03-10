/// TimelinePage - Hour-by-Hour Schedule View
/// 
/// Displays events in a vertical timeline format organized by time of day.
/// 
/// Features:
/// - Scrollable hour-by-hour schedule for selected date
/// - Events positioned based on their start time
/// - Color-coded by event classification
/// - Navigation to previous/next days with date picker
/// - Tap event to view/edit details
/// - Current time indicator
/// - All-day events displayed at top
/// 
/// Syncs with DataProvider to show real-time event updates.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';
import 'event_action_dialog.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final itemHeight = 100.0;
    final scrollPosition = now.hour * itemHeight;
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final now = DateTime.now();
        final isToday = _selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day;
        
        return Scaffold(
          appBar: AppBar(
  title: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.meetingTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.timeline_rounded,
          color: AppTheme.meetingTeal,
          size: 22,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          isToday 
              ? 'Timeline - Today'
              : 'Timeline - ${DateFormat('MMM dd').format(_selectedDate)}',
          style: Theme.of(context).textTheme.titleLarge,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  ),
            actions: [
              IconButton(
                icon: const Icon(Icons.auto_fix_high_rounded),
                onPressed: () => _showAIRescheduleDialog(context, dataProvider),
                tooltip: 'AI Reschedule',
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: _selectDate,
                tooltip: 'Select Date',
              ),
              if (!isToday)
                IconButton(
                  icon: const Icon(Icons.today),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                    _scrollToCurrentTime();
                  },
                  tooltip: 'Jump to Today',
                ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: 24,
                itemBuilder: (context, index) {
                  final hour = index;
                  final isCurrentHour = isToday && hour == now.hour;
                  
                  return _buildTimelineBlock(context, hour, isCurrentHour, dataProvider, index);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ── AI Reschedule Dialog ─────────────────────────────────────────────────
  Future<void> _showAIRescheduleDialog(
      BuildContext context, DataProvider dataProvider) async {
    final events = dataProvider.getEventsForDay(_selectedDate);

    // Track which events are selected (all selected by default)
    final Map<String, bool> selectedEvents = {
      for (final e in events) e.id: true,
    };

    TimeOfDay sleepStart = const TimeOfDay(hour: 23, minute: 0);
    TimeOfDay sleepEnd = const TimeOfDay(hour: 7, minute: 0);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return _AIRescheduleDialog(
          selectedDate: _selectedDate,
          events: events,
          initialSelectedEvents: selectedEvents,
          initialSleepStart: sleepStart,
          initialSleepEnd: sleepEnd,
        );
      },
    );
  }

  Widget _buildTimelineBlock(
    BuildContext context,
    int hour,
    bool isCurrentHour,
    DataProvider dataProvider,
    int index,
  ) {
    final blockTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
    );
    
    final events = dataProvider.getEventsForDay(_selectedDate).where((event) {
      return event.startTime.hour == hour;
    }).toList();
    
    final hasItems = events.isNotEmpty;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time label
        SizedBox(
          width: 70,
          child: Text(
            DateFormat('h:mm a').format(blockTime),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 13,
              fontWeight: isCurrentHour ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'monospace',
              color: isCurrentHour 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
        
        // Timeline rail
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isCurrentHour 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.transparent,
                border: Border.all(
                  color: isCurrentHour 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
            ),
            if (hour < 23)
              Container(
                width: 2,
                height: hasItems ? (events.length * 110.0) : 70,
                color: isCurrentHour 
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                    : Theme.of(context).dividerColor,
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Event blocks
        Expanded(
          child: hasItems
              ? Column(
                  children: events.map((event) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildEventCard(context, event, isCurrentHour),
                    );
                  }).toList(),
                )
              : const SizedBox(height: 70),
        ),
      ],
    ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event, bool isCurrentHour) {
    final color = AppTheme.getClassificationColor(event.classification);
    final icon = AppTheme.getClassificationIcon(event.classification);
    
    String duration;
    if (event.hasEndTime) {
      final diff = event.endTime!.difference(event.startTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      duration = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    } else {
      duration = event.estimatedDuration ?? '—';
    }
    
    String subtitle = '';
    if (event.location != null && event.location!.isNotEmpty) {
      subtitle = event.location!;
    } else if (event.category != null) {
      final category = Provider.of<DataProvider>(context, listen: false)
          .getCategoryById(event.category);
      if (category != null) {
        subtitle = category.name;
      }
    }
    
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => EventActionDialog(event: event),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentHour ? color : color.withValues(alpha: 0.3),
            width: isCurrentHour ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        event.classification[0].toUpperCase() + 
                            event.classification.substring(1),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                decoration: event.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    event.location != null 
                        ? Icons.location_on_outlined 
                        : Icons.folder_outlined,
                    size: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (event.isImportant)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppTheme.warningAmber),
                    const SizedBox(width: 4),
                    Text(
                      'Important',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warningAmber,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),        ),      ),
    );
  }
}

// ── AI Reschedule Dialog (separate StatefulWidget) ───────────────────────────
class _AIRescheduleDialog extends StatefulWidget {
  final DateTime selectedDate;
  final List<Event> events;
  final Map<String, bool> initialSelectedEvents;
  final TimeOfDay initialSleepStart;
  final TimeOfDay initialSleepEnd;

  const _AIRescheduleDialog({
    required this.selectedDate,
    required this.events,
    required this.initialSelectedEvents,
    required this.initialSleepStart,
    required this.initialSleepEnd,
  });

  @override
  State<_AIRescheduleDialog> createState() => _AIRescheduleDialogState();
}

class _AIRescheduleDialogState extends State<_AIRescheduleDialog> {
  late Map<String, bool> _selectedEvents;
  late TimeOfDay _sleepStart;
  late TimeOfDay _sleepEnd;

  @override
  void initState() {
    super.initState();
    _selectedEvents = Map.from(widget.initialSelectedEvents);
    _sleepStart = widget.initialSleepStart;
    _sleepEnd = widget.initialSleepEnd;
  }

  String _formatTOD(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime(bool isSleepStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isSleepStart ? _sleepStart : _sleepEnd,
    );
    if (picked != null) {
      setState(() {
        if (isSleepStart) {
          _sleepStart = picked;
        } else {
          _sleepEnd = picked;
        }
      });
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.meetingTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_fix_high_rounded,
                  color: AppTheme.meetingTeal, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('What is AI Rescheduling?',
                  style: TextStyle(fontSize: 17)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Rescheduling analyses your day\'s events and intelligently redistributes them to:',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.6),
            ),
            const SizedBox(height: 14),
            ...[
              (Icons.balance_rounded,
                  'Balance workload to avoid burnout'),
              (Icons.schedule_rounded,
                  'Respect your sleep schedule and personal boundaries'),
              (Icons.priority_high_rounded,
                  'Prioritise high-importance and time-sensitive tasks'),
              (Icons.coffee_rounded,
                  'Insert appropriate breaks between sessions'),
              (Icons.warning_amber_rounded,
                  'Resolve conflicting or overlapping events'),
            ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.meetingTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(item.$1,
                            size: 15, color: AppTheme.meetingTeal),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.$2,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    height: 1.5,
                                    fontSize: 14.5,
                                  ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.warningAmber.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: AppTheme.warningAmber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only the events you select will be considered for rescheduling.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.5,
                            color: AppTheme.warningAmber,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.meetingTeal),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('EEEE, MMMM d').format(widget.selectedDate);
    final selectedCount =
        _selectedEvents.values.where((v) => v).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 520,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.meetingTeal,
                    AppTheme.meetingTeal.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_fix_high_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Reschedule',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ? Info button
                  IconButton(
                    onPressed: _showInfoDialog,
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.question_mark_rounded,
                          color: Colors.white, size: 16),
                    ),
                    tooltip: 'What is AI Rescheduling?',
                  ),
                  // Close
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ──────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Events section
                    Row(
                      children: [
                        Icon(Icons.event_note_rounded,
                            size: 18, color: AppTheme.meetingTeal),
                        const SizedBox(width: 8),
                        Text(
                          'Events to reschedule',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          '$selectedCount / ${widget.events.length} selected',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppTheme.meetingTeal,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (widget.events.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_busy_rounded,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color),
                            const SizedBox(width: 10),
                            Text(
                              'No events on this day.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    else
                      ...widget.events.map((event) {
                        final color = AppTheme.getClassificationColor(
                            event.classification);
                        final isSelected =
                            _selectedEvents[event.id] ?? false;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => setState(() =>
                                _selectedEvents[event.id] = !isSelected),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color.withValues(alpha: 0.08)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.4)
                                      : Theme.of(context).dividerColor,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    AppTheme.getClassificationIcon(
                                        event.classification),
                                    size: 18,
                                    color: isSelected
                                        ? color
                                        : Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          DateFormat('h:mm a')
                                              .format(event.startTime),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: isSelected
                                                    ? color
                                                    : null,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: color,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4)),
                                    onChanged: (v) => setState(() =>
                                        _selectedEvents[event.id] =
                                            v ?? false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 20),

                    // Sleep schedule section
                    Row(
                      children: [
                        Icon(Icons.bedtime_rounded,
                            size: 18, color: AppTheme.accentPurple),
                        const SizedBox(width: 8),
                        Text(
                          'Sleep Schedule',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The AI will avoid scheduling events during your sleep window.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.4,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withValues(alpha: 0.8),
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimePicker(
                            context,
                            label: 'Bedtime',
                            icon: Icons.nights_stay_rounded,
                            time: _sleepStart,
                            color: AppTheme.accentPurple,
                            onTap: () => _pickTime(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTimePicker(
                            context,
                            label: 'Wake up',
                            icon: Icons.wb_sunny_rounded,
                            time: _sleepEnd,
                            color: AppTheme.examOrange,
                            onTap: () => _pickTime(false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: AppTheme.meetingTeal.withValues(alpha: 0.05),
                border: Border(
                    top: BorderSide(
                        color: AppTheme.meetingTeal.withValues(alpha: 0.2))),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: selectedCount == 0
                      ? null
                      : () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: Row(
                                children: [
                                  Icon(Icons.auto_fix_high_rounded,
                                      color: AppTheme.meetingTeal),
                                  const SizedBox(width: 10),
                                  const Text('Not Implemented Yet'),
                                ],
                              ),
                              content: const Text(
                                'AI-powered rescheduling is coming soon! '
                                'This feature will automatically optimise your schedule '
                                'based on your selected events and preferences.',
                              ),
                              actions: [
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: FilledButton.styleFrom(
                                      backgroundColor:
                                          AppTheme.meetingTeal),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: Text(
                    selectedCount == 0
                        ? 'Select at least one event'
                        : 'Generate Schedule ($selectedCount event${selectedCount == 1 ? '' : 's'})',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.meetingTeal,
                    disabledBackgroundColor:
                        AppTheme.meetingTeal.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required IconData icon,
    required TimeOfDay time,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTOD(time),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: color,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, size: 14, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
