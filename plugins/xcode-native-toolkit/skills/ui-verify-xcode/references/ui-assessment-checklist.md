# UI Assessment Checklist

When reading a simulator screenshot, evaluate these criteria. Report findings as:
**PASS**, **ISSUE** (with description), or **UNCLEAR** (need different angle/state).

## Layout and Structure

- Content within safe areas (no overlap with notch, home indicator, status bar)
- Navigation elements (tab bar, nav bar, sidebar) positioned correctly
- Content does not clip or overflow its container
- Scroll views show appropriate content (no excess whitespace)
- Modal/sheet presentations have correct sizing
- Split views render correctly (iPad/macOS)

## Typography

- Text is legible at displayed size
- No unintended text truncation
- Ellipsis used appropriately for long text
- Font weights are consistent (headings bold, body regular)
- Text color has sufficient contrast against background
- No overlapping text labels

## Color and Theming

- Colors match design intent / brand
- Light mode: light backgrounds, dark text
- Dark mode: dark backgrounds, light text (if tested)
- Accent color consistent on interactive elements
- System colors used where appropriate for automatic dark mode support

## Spacing and Alignment

- Elements align to a consistent grid
- Spacing between elements is uniform
- Leading/trailing margins are equal
- List items have consistent row heights
- Section headers have appropriate spacing above/below

## Interactive Elements

- Buttons clearly identifiable as tappable
- Minimum tap target appears at least 44x44pt
- Disabled states visually distinct
- Selected/active states visible (tab bar, segmented control)
- Text fields have visible borders or backgrounds

## Platform Conventions

### iOS
- Navigation bar title and back button present
- Tab bar at bottom with appropriate icons
- Content extends under translucent bars appropriately
- Large title collapses on scroll (if applicable)

### macOS
- Window title bar present and correct
- Toolbar items properly spaced
- Sidebar width appropriate
- Window resizing behavior correct

## Accessibility

- Sufficient color contrast (4.5:1 normal text, 3:1 large text)
- Information not conveyed by color alone
- Touch targets adequately sized
- Content readable at increased Dynamic Type sizes

## Edge Cases to Test

- **Empty state**: What shows with no data?
- **Loading state**: Spinner or skeleton present?
- **Error state**: How are errors displayed?
- **Long content**: Text wraps or truncates appropriately?
- **Many items**: Long list scrolls correctly?
- **Keyboard visible**: Content shifts to remain visible?

## Reporting Format

```
## UI Verification: [Screen Name]

**Device:** iPhone 16 Pro (iOS 18)
**Mode:** Light / Dark
**Text Size:** Default

### PASS
- Layout respects safe areas
- Navigation bar renders correctly

### ISSUES
- [CRITICAL] Dark mode: white text on white background (unreadable)
- [MAJOR] Subtitle label truncates at default width
- [MINOR] Bottom padding insufficient — last item touches tab bar

### RECOMMENDATIONS
1. Use .secondarySystemBackground for card in dark mode
2. Allow subtitle to wrap to 2 lines
3. Add 16pt bottom padding to list content inset
```
