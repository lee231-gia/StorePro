# PLAN: StorePro UI Modernization & Full Redesign

## Summary
Modernize the entire StorePro Flutter POS app: fresh color palette, dark mode support, responsive/adaptive layout, skeleton loaders, micro-animations, and refactored page structure — without changing any business logic.

## Color Palette (Chosen: Deep Slate Teal + Warm Amber)
| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| Primary | `#1A5C5C` (Slate Teal) | `#4DB6AC` (Teal Glow) | AppBars, buttons, active states |
| Primary Container | `#E0F2F1` | `#1A3A3A` | Selected chips, light backgrounds |
| Accent / Secondary | `#C9A84C` (Gold) | `#D4B85A` | Highlights, badges, call-to-action |
| Surface | `#FAF8F5` (Warm Off-white) | `#121416` (Deep Charcoal) | Cards, sheets |
| Background | `#F0EDE8` | `#0D0F10` | Page backgrounds |
| On Surface | `#1A1D1F` | `#E8E6E1` | Body text |
| On Surface Dim | `#6B7280` | `#9CA3AF` | Secondary text |
| Border | `#E5E2DC` | `#2A2D30` | Dividers, borders |
| Success | `#2E7D32` | `#4CAF50` | Status |
| Error | `#C62828` | `#EF5350` | Status |
| Warning | `#E65100` | `#FF7043` | Status |

## Approach
1. **Theme System First** — Replace hardcoded colors with a `StoreProTheme` that provides light + dark `ThemeData`. Keep Poppins font, introduce the palette above.
2. **Refactor Foundation** — Update `app_colors.dart` → new palette, `app.dart` → dual theme + responsive shell, `shared_widgets.dart` → theme-aware components.
3. **Page-by-Page Refactor** — Work through each page from most-impactful to least, extracting inline widgets and applying the new theme. Break up the 3 largest pages (sales, utang, dashboard).
4. **Skeleton Loaders** — Create `AppSkeleton` widget and add loading states to all pages.
5. **Micro-animations** — Add `AnimatedSwitcher`, `Hero`, subtle transitions.
6. **Adaptive Layout** — Add `LayoutBuilder` breakpoints to the navigation shell and key pages.

## Subtasks

### T1 — Theme System (`lib/core/theme/`)
- Create `lib/core/theme/app_theme.dart` with light + dark `ThemeData`
- Create `lib/core/theme/app_palette.dart` with new color tokens
- Create `lib/core/theme/theme_provider.dart` (ChangeNotifier for theme mode)
- Update `lib/main.dart` to initialize `ThemeProvider`
- Update `lib/app.dart` to consume theme provider and switch themes
- Update `lib/core/constants/app_colors.dart` with backward-compat aliases

### T2 — Refactor Navigation Shell (`lib/app.dart` + `lib/widgets/app_drawer.dart`)
- Replace `Drawer` with a responsive layout that uses `NavigationRail` on tablets/desktop and `Drawer` on phones
- Add `LayoutBuilder` breakpoints in `MainNavPage`
- Theme-ify the drawer header and nav items
- Add smooth page transition animation

### T3 — Modernize Shared Widgets (`lib/widgets/shared_widgets.dart`)
- Make `buildAppBar`, `AppInput`, `PrimaryButton`, `OutlineBtn`, `appCard`, `statusBadge` all theme-aware (use `Theme.of(context)` colors instead of hardcoded `kRed`, `kGrey`)
- Add shimmer/skeleton loading variant to `appCard`
- Create `AppSkeleton` widget (shimmer line/box/circle)

### T4 — Refactor Dashboard Page (`lib/pages/dashboard/`)
- Create `lib/pages/dashboard/dashboard_controller.dart` (ChangeNotifier with data loading logic extracted from the StatefulWidget)
- Create `lib/pages/dashboard/widgets/` folder:
  - `dashboard_welcome_card.dart` (redesigned)
  - `dashboard_overview_section.dart`
  - `dashboard_quick_actions.dart`
  - `dashboard_expiry_section.dart`
  - `dashboard_low_stock_section.dart`
  - `dashboard_activity_section.dart`
- Add skeleton loading states
- Add `AnimatedSwitcher` for data refreshes
- Make responsive with `LayoutBuilder`

### T5 — Refactor Sales Page (`lib/pages/sales/`)
- Split `sales_page.dart` (1,263 lines) into focused files:
  - `sales_page.dart` (shell only, 2 tabs)
  - `sales_new_sale.dart` (new sale tab: product browser + cart)
  - `sales_history.dart` (history tab)
  - `sales_edit_dialog.dart` (extracted edit dialog)
  - `sales_controller.dart` (ChangeNotifier)
- Apply new theme
- Add skeleton loading for sale history

### T6 — Refactor Utang Page (`lib/pages/utang/`)
- Split `utang_page.dart` (997 lines) into:
  - `utang_page.dart` (shell)
  - `utang_list.dart`
  - `utang_detail_sheet.dart`
  - `utang_dialogs.dart`
  - `utang_controller.dart`
- Apply new theme

### T7 — Refactor Products Page (`lib/pages/products/`)
- Split `add_product_page.dart` + 6 part-files → cleaner structure
- Theme-ify product cards
- Add skeleton loading for product grids
- Add staggered grid animation

### T8 — Apply Theme to All Remaining Pages
- Inventory page
- Expiry page
- Categories page
- Customers page
- Notes page
- Reports page
- Settings page
- Auth pages (welcome, login, signup, forgot password)

### T9 — Skeleton & Empty States
- Create reusable `AppSkeleton` widget (shimmer effect)
- Create `AppSkeletonList`, `AppSkeletonGrid`, `AppSkeletonCard`
- Add to all pages that fetch data
- Ensure `AppEmptyState` is used consistently across all pages

### T10 — Micro-animations & Polish
- Page transitions: `CustomTransitionPage` with fade + slide
- Hero animations for product images
- `AnimatedContainer` for card hover/press effects
- `AnimatedSwitcher` for tab content changes
- Button press feedback (scale animation)

### T11 — Dark Mode Persistence
- Save theme preference to SharedPreferences/local storage
- Load on app start
- Toggle in settings page

### T12 — Adaptive/Responsive Layout
- `NavigationRail` for screens >= 600px width
- Responsive grid columns for product browser
- Split-pane layout for sale screen on tablet
- Responsive dialogs (full-screen on mobile, centered dialog on desktop)

### T13 — Polish & Cleanup
- Audit all files for remaining hardcoded `Colors.grey`, `kRed` references
- Ensure all widgets consume theme
- Remove dead code
- Verify all routes still work

## Files Touched
- **New:** ~25 files under `lib/core/theme/`, `lib/shared/widgets/`, `lib/pages/*/widgets/`, `lib/pages/*/controllers/`
- **Modified:** ~40 existing files across `lib/`
- **No changes to:** `lib/core/services/`, `lib/models/`, `lib/repositories/`, `lib/core/utils/` (preserve business logic)

## Risks
- **Regression risk**: High due to scale. Mitigated by preserving all model/repository/service code untouched and working page-by-page with verification.
- **ThemeProvider initialization**: Must be above `MaterialApp` in widget tree or app will flash wrong theme. Handled in `main.dart`.
- **Dark mode contrast**: All color pairs must pass WCAG AA contrast ratio. Palette chosen with this in mind.
- **Large file splits**: Must ensure all callbacks and state flow correctly after extraction.

## Non-Goals
- No business logic changes
- No database schema changes
- No Firebase/Firestore changes
- No new features (pure UI modernization)
- No Riverpod/Bloc migration (ChangeNotifier retained for stability; the refactoring into controllers IS the improvement)
