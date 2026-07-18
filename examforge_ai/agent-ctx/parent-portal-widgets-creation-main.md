# Parent Portal Widgets Creation

## Task
Create shared widgets for the Parent Portal module under `/home/z/my-project/examforge_ai/lib/features/parent_portal/presentation/widgets/`

## Files Created

### 1. `child_selector_dropdown.dart`
- `ChildSelectorDropdown` (ConsumerWidget-based signature, implemented as StatelessWidget)
- Dropdown for selecting which child to view data for
- Shows avatar circle with first letter of child's name, name + class, dropdown arrow
- If only one child, shows name without dropdown
- Uses PopupMenuButton for multi-child dropdown
- Follows project patterns: AppColors, Spacings, AppTypography, context extensions

### 2. `child_summary_card.dart`
- `ChildSummaryCard` (StatelessWidget)
- Card showing large avatar, child name (bold), class, relationship badge
- Attendance rate row with colored progress bar + percentage
- Pending assignments count with warning/success styling
- Latest results: up to 3 small score badges with subject + grade
- Right arrow icon, tap → navigates to child profile

### 3. `attendance_calendar.dart`
- `AttendanceCalendar` (StatelessWidget)
- Monthly calendar grid with Mon–Sun headers
- Day cells colored by status: present=green, absent=red, late=amber, excused=blue
- Today has primary color border, weekends dimmed to 60% opacity
- Legend dots for P/A/L/E status
- Tap day → onDaySelected callback with DateTime

### 4. `insight_card.dart`
- `InsightCard` (StatelessWidget)
- Left color bar (4px) based on InsightSeverity: info=blue, warning=amber, concern=red, positive=green
- Insight type badge with icon
- Title (semi-bold), description (2 lines max)
- Recommendations preview (first 2 items with bullet points)
- Dismiss X button (top-right)
- AI-generated indicator + time ago (bottom-right)

### 5. `message_bubble.dart`
- `MessageBubble` (StatelessWidget)
- Rounded rectangle with asymmetric tail corners
- isMe: right-aligned, primary color background, white text
- not isMe: left-aligned, surface variant background, sender name above
- Message body text, time display below
- Read status (double checks) for sent messages
- Attachment indicator when attachments exist
- Small avatar circles for sender/receiver

### 6. `notification_list_tile.dart`
- `NotificationListTile` (StatelessWidget)
- Category icon (left) with color coding: result=trending_up, attendance=calendar_today, assignment=assignment, announcement=campaign, exam=quiz, message=chat, fee=payments
- Unread dot indicator (blue, top-left of icon)
- Title (bold if unread), body preview (1 line, grey)
- Time ago display, action button if actionUrl exists
- Swipe to dismiss with Dismissible widget

### 7. `performance_indicator.dart`
- `PerformanceIndicator` (StatelessWidget)
- Custom painter: 270° circular progress arc
- Color based on score: green (>70), amber (50–70), red (<50)
- Score text in center (large, bold)
- Optional label below score
- Class average marker on the arc (filled circle with white inner dot)
- Arc starts at 135° (bottom-left), sweeps clockwise

### 8. `engagement_metric_card.dart`
- `EngagementMetricCard` (StatelessWidget)
- Compact card with icon in color background circle (32×32)
- Count number (large, bold) with K/M formatting
- Title text below
- Optional subtitle (smaller grey text)

### 9. `parent_portal_widgets.dart` (barrel export)
- Exports all 8 widget files

## Patterns Followed
- All widgets use `AppColors`, `Spacings`, `AppTypography`, context extensions (`context.colorScheme`, `context.textTheme`, `context.isDarkMode`)
- Import paths: `../../../../core/themes/app_colors.dart`, etc.
- Entity import: `../../domain/entities/parent_portal_entities.dart`
- Consistent spacing with `Spacings.*` constants
- Typography weights with `AppTypography.wBold/wSemiBold/wMedium`
- Dark mode support via `isDark` checks
- Card-based layouts with `Spacings.elevationSm` and `Spacings.lgRadius`
