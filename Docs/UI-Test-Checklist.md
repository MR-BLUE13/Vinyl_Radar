# UI Test Checklist (for App Target Integration)

These checks map to phase-1 acceptance and can be automated once an iOS app/UI-test target is added:

1. Feed screen renders header (`Radar` + `Limited Vinyl Drops`), summary strip, chips, and card list.
2. Switching chips updates list contents for each filter.
3. Tapping a card navigates to `ReleaseDetailView` skeleton.
4. Toggling bookmark updates icon state and persists after navigating back.
5. Empty state and error state are visible and retry recovers correctly.
