# Engineering, prose, and release audit

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Keep version 0.1.9. RubyGems still lists 0.1.8; tag 0.1.9 is missing. Fold audit fixes into the unpublished 0.1.9 cut and date the product changelog 2026-11-03.
- Run engineering audit (pipeline, HTTP identity, client surface, contracts, resource notes) and iterative prose audit on README, locales, RFCs, and changelog. Apply smallest credible fixes before publish.
- Do not tag, push, or gem-push from this session until the worktree is committed and `make release` is confirmed.

## Effects

Engineering findings fixed with executable coverage:

- OptionsController now calls `protect_from_forgery with: :exception` so CSRF does not depend only on the host ApplicationController template. Request example enables forgery protection and expects `:unprocessable_content` for an invalid token.
- Finder.normalize_results returns [] when the host finder returns nil, without wrapping Enumerators via Array.wrap (that path broke lazy `take`).
- Navigate breadcrumb separator is ASCII ` > `. Locale and default help or loading strings use ASCII punctuation. RFC 0004 text matches.
- RFC 0007 and RFC 0008 marked Stable; rfcs/README and install README list them with 0003 through 0006.

Prose audit iterations:

1. Unicode punctuation and RFC status drift in README, locales, RFCs, compiler help, and JS defaults.
2. Re-read Finnish and Swedish locales: keep language letters; only replace ellipsis, em dashes, and key glyphs in footers.
3. CHANGELOG and design RFC index for marketing odor and stale Proposed status: none beyond the Stable promotion.

Follow-up from the parallel engineering audit pass:

- Prefer AdminUser Devise sign-in helper before User; return resolved href from client URL checks.
- Strengthen README host checklist (policy scope, POST preference, rate limit). Document that the dummy finder uses `.all` only because the dummy has no auth library.

Checks observed in this session:

- bundle exec rspec on finder, helper, and options request specs: pass, including nil finder, CSRF, and sign-in path examples.
- make test-javascript: pass, including resolved relative navigation URL.
- RuboCop 51 files clean; full rspec 51 examples (before helper examples added). Re-run the full suite before publish.

## Next

- Commit the audit fixes on main when ready.
- Run `make release` from a clean tree (gem push, tag 0.1.9, GitHub release).
- Hosted GitHub Actions and the full appraisal matrix inside make release remain the publish gate.

## Source

- AGENTS.md, .agents/skills/engineering-audit/, .agents/skills/changelog-update/
- docs/reviews/20261029173255_engineering-audit-release-preparation.md
- docs/changelogs/20261029173255_release-0-1-9.md
- CHANGELOG.md, lib/activeadmin/command_palette/version.rb
