import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'logic/timeline_provider.dart';
import 'models/timeline_event.dart';
import 'widgets/timeline_node.dart';
import '../../shared/utils/format_utils.dart';
import '../home/widgets/multi_select_filter_delegate.dart';

class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineEventsProvider);
    final selectedFilter = ref.watch(timelineFilterProvider);
    final theme = Theme.of(context);

    // Color definitions for lines
    final yearLineColor = theme.colorScheme.primary.withValues(alpha: 0.5);
    final monthLineColor = theme.colorScheme.secondary.withValues(alpha: 0.5);
    final dayLineColor = theme.colorScheme.tertiary.withValues(alpha: 0.3);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            leading: const BackButton(),
            title: Text(
              '物历', 
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            ),
            centerTitle: true,
            toolbarHeight: 44,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: theme.scaffoldBackgroundColor,
          ),
          
          SliverPersistentHeader(
            pinned: true,
            delegate: MultiSelectFilterDelegate(
              selectedCategories: selectedFilter,
              onSelectionChanged: (categories) {
                 ref.read(timelineFilterProvider.notifier).state = categories;
              },
            ),
          ),
          
          timelineAsync.when(
            data: (timelineYears) {
              if (timelineYears.isEmpty) {
                 return SliverFillRemaining(
                   child: Center(
                     child: Text(
                       '暂无记录',
                       style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
                     ),
                   ),
                 );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final yearData = timelineYears[index];
                    final isLastYear = index == timelineYears.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Level 1: Year Line
                          _buildLine(
                            context, 
                            color: yearLineColor, 
                            isLast: isLastYear, 
                            width: 20
                          ),
                          
                          // Year Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Year Header
                                _buildYearHeader(context, yearData.year, yearData.totalCost),
                                
                                // Months
                                ...yearData.months.map((monthData) {
                                   final isLastMonth = monthData == yearData.months.last;
                                   
                                   return IntrinsicHeight(
                                     child: Row(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                          // Level 2: Month Line
                                          _buildLine(
                                            context,
                                            color: monthLineColor,
                                            isLast: isLastMonth,
                                            width: 20,
                                          ),
                                          
                                          // Month Content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Month Header
                                                _buildMonthHeader(context, monthData),
                                                
                                                // Days
                                                ...() {
                                                  // Group by Day (Duplicated logic from previous, consider moving to provider if complex)
                                                  final eventsByDay = <int, List<TimelineEvent>>{};
                                                  for (var e in monthData.events) {
                                                    eventsByDay.putIfAbsent(e.date.day, () => []).add(e);
                                                  }
                                                  final sortedDays = eventsByDay.keys.toList()..sort((a, b) => b.compareTo(a));
                                                  
                                                  return sortedDays.map((day) {
                                                    final dayEvents = eventsByDay[day]!;
                                                    final dayTotal = dayEvents.fold(0.0, (sum, e) => sum + e.cost);
                                                    final isLastDay = day == sortedDays.last;

                                                    return IntrinsicHeight(
                                                      child: Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          // Level 3: Day Line
                                                          _buildLine(
                                                            context,
                                                            color: dayLineColor,
                                                            isLast: isLastDay,
                                                            width: 20
                                                          ),
                                                          
                                                          // Day Content (Nodes)
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                _buildDayHeader(context, monthData.month, day, dayTotal),
                                                                
                                                                ...dayEvents.map((event) => TimelineNode(event: event)),
                                                                
                                                                const SizedBox(height: 12),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  });
                                                }(),
                                                
                                                const SizedBox(height: 8),
                                              ],
                                            ),
                                          ),
                                       ],
                                     ),
                                   );
                                }),
                                
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: (50 * index).ms);
                  },
                  childCount: timelineYears.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  // Helper to build a vertical line column
  Widget _buildLine(BuildContext context, {required Color color, required bool isLast, double width = 16}) {
    return SizedBox(
      width: width,
      child: Stack(
         alignment: Alignment.topCenter,
         children: [
           // The continuous line
           // If isLast is true, we might want to stop the line at some point?
           // For simple continuous look, year lines usually connect.
           // User request: "Year and Year connect". So do NOT hide line if isLastYear?
           // Actually, if it's strictly hierarchical, the last year shouldn't have a line trailing into nothingness.
           // But timeline implies continuity.
           // Let's keep it simple: Line always exists unless it clearly ends the list.
           
           if (!isLast) 
             Positioned(
               top: 0, 
               bottom: 0, 
               child: Container(width: 1, color: color),
             ),
             
           // But we need the line to at least reach the current item's "dot".
           // Since we use rows, we can just let 'Expanded' children dictact height.
           // If isLast, we still want the line to go from top to the "Header" position and maybe stop?
           // Let's implement a full height line for now, except for the very last item of the entire list.
           // However, inside IntrinsicHeight, Expanded/Positioned works well.
           
           if (isLast)
             // Last item line: only goes halfway? 
             // Or just full height but transparent at bottom? 
             // Let's Draw a line that fits the content.
             Positioned(
               top: 0,
               bottom: 0, // Fill ensures it connects to children
               child: Container(width: 1, color: color),
             ),

            // We can add a "Dot" or "Branch" indicator at the top if we want tree style.
            // For now, simple lines.
         ],
      ),
    );
  }

  Widget _buildYearHeader(BuildContext context, int year, double totalCost) {
     final theme = Theme.of(context);
     return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8), // Reduced vertical
       child: Row(
         children: [
           Container(
             width: 8, height: 8, 
             decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary),
           ),
           const SizedBox(width: 8), // Reduced gap
           Text('$year', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)), // Reduced size
           const SizedBox(width: 4),
           Text('年', style: theme.textTheme.titleSmall),
           const Spacer(),
           Padding(
             padding: const EdgeInsets.only(right: 16.0),
             child: Text('¥${FormatUtils.formatCurrency(totalCost)}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
           )
         ],
       ),
     );
  }

  Widget _buildMonthHeader(BuildContext context, MonthlyTimeline monthData) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4), // Reduced vertical
      child: Row(
        children: [
          Container(
             width: 6, height: 6, 
             decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.secondary),
           ),
           const SizedBox(width: 8),
          Text('${monthData.month}月', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Text('¥${FormatUtils.formatCurrency(monthData.totalCost)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          )
        ],
      ),
    );
  }

  Widget _buildDayHeader(BuildContext context, int month, int day, double totalCost) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
           Container(
             width: 4, height: 4, 
             decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.tertiary),
           ),
           const SizedBox(width: 12),
           Text('${month}月${day}日', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.tertiary)),
           const Spacer(),
           Padding(
             padding: const EdgeInsets.only(right: 16.0),
             child: Text('¥${FormatUtils.formatCurrency(totalCost)}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
           )
        ],
      ),
    );
  }
}
