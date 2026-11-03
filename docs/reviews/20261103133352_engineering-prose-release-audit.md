# Engineering and prose audit before 0.1.9 publish

## Participants

Andrei Makarov (@amkisko)

## Decisions

Re-audit main for the unpublished 0.1.9 cut. Include CSRF ownership on OptionsController, nil finder handling, ASCII UI and docs punctuation, and Stable status for RFC 0007 and RFC 0008. Leave tag and RubyGems publish to `make release` after commit.

## Effects

Pipeline: ingress OptionsController -> Finder / Catalog -> Stimulus client egress. Boundary mode covered CSRF, confirm gates, and URL allow-list already present on the client. Resource and identification modes: no new emission; sessionStorage recent keys unchanged. Queue, worker, learned-system, and physical plant modes skipped (absent).

Ranked fixes applied:

1. CSRF declared on OptionsController (high confidence, observed).
2. Nil finder payload returns [] without breaking Enumerator#take (high confidence, observed).
3. ASCII punctuation in locales, breadcrumbs, help, and README (medium severity, house prose).
4. RFC 0007 and 0008 Stable (process accuracy).

Checks: RuboCop 51 files clean; rspec 51 examples 0 failures; JavaScript 13 pass. RubyGems latest remains 0.1.8 until publish.

## Next

Commit, then `make release`.

## Source

- docs/issues/20261103133352_engineering-prose-release-audit.md
- CHANGELOG.md section 0.1.9 (2026-11-03)
