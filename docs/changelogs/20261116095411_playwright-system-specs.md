# Browser system specs

## Participants

Andrei Makarov

## Decisions

Treat browser system specs as mandatory for this gem. Reuse the house
`:railsfi` driver, `.playwright-version` pin, and TestEnv helpers. Cover palette
open, keyboard filter, ActiveAdmin-owned finder options, and admin GraphQL
endpoint coexistence.

## Effects

- Dummy ActiveAdmin layout boots Stimulus and the palette controller.
- CI installs Chromium from `.playwright-version` before Polyrun.
- Coverage stays in specs and contributor docs; product CHANGELOG omits
  driver and sibling-package names.

## Next

Folded into release 0.2.0 (docs/changelogs/20261116131700_release-0-2-0.md).

## Source

- `spec/system/`
- `spec/support/playwright.rb`
- `spec/support/test_env.rb`
- `.github/workflows/test.yml`
