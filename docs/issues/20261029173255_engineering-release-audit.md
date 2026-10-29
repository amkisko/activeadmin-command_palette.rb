# Engineering and release audit

## Participants

Andrei Makarov (@amkisko)

## Decisions

Prepare 0.1.9 as a patch release on main. Keep the pre-existing uncommitted runtime, release-tooling, and documentation changes. Do not commit, tag, push, or publish.

Review client navigation with unavailable browser storage, release confirmation EOF handling, executable tests, GitHub Actions permissions, packaging, resource budgets, and release metadata. There is no independently operated worker, learned system, cloud deployment, physical plant, or message broker in this library, so those surface-specific modes do not apply. Browser presentation applies to the Stimulus palette controller.

## Effects

All listed fixes have high confidence and observed evidence from failing-then-passing executable tests or built-package inspection.

- sessionStorage.setItem threw when browser storage was disabled or full, so remember aborted before location.assign. Catch the write failure and keep navigation. JavaScript regression: navigates when recent-item storage is unavailable.
- Release confirmation converted EOF to an empty affirmative answer via String#chomp on nil. Add ReleaseVersionCheck.confirmation_accepted? and reject EOF while preserving an entered empty line and y. Unit examples cover yes, default Enter, n, and nil. Process-boundary examples load usr/bin/release.rb with Kernel#system stubbed so no real publish command runs.
- Restrict the test workflow to contents: read and cancel superseded runs. pull_request remains enabled for branches that open against the repository.

Checks with Ruby 4.0.2 on arm64 macOS:

- RUBOCOP_CACHE_ROOT=tmp/rubocop_cache make test: exit 0, including Biome, RuboCop, RBS validation, 13 JavaScript tests, and five Polyrun workers.
- bundle exec rspec --format progress: 49 examples, 0 failures, including four ReleaseVersionCheck examples (helper plus process boundary).
- Coverage merge: 95.95% (497/518) tracked lines. Coverage is evidence for those assertions, not proof of all behavior.
- gem build with output tmp/activeadmin-command_palette-0.1.9.gem, followed by Gem::Package#verify: pass. 28160 compressed bytes, 32 packaged files. Version, changelog heading, and path-package lock entries agree on 0.1.9.
- git diff --check: pass. Branch remains main. RubyGems latest published version remains 0.1.8.

Resource fixtures are local. Version-only cold load (`bundle exec ruby -Ilib` requiring version.rb), measured with `/usr/bin/time -l`: 0.17 CPU seconds and 27721728 bytes maximum RSS. Dummy host cold load (`spec/dummy/config/environment`) measured 1.30 CPU seconds and 146063360 bytes maximum RSS; that process boots Rails, ActiveAdmin, and the test app. CPU seconds are the energy proxy; no energy meter was available. Controller raw size 25639 bytes, gzip 6555 bytes. These are single-machine observations, not release budgets for co-located production hosts.

## Next

Review the worktree and commit when ready. Run `make release` from a clean tree to build, push the gem, tag, and create the GitHub release. No release has been published.

## Source

- AGENTS.md and .agents/skills/engineering-audit/.
- .agents/skills/changelog-update/.
- CHANGELOG.md, spec/, .github/workflows/test.yml, usr/bin/release.rb, usr/lib/release_version_check.rb.
- docs/reviews/20261029173255_engineering-audit-release-preparation.md.
- docs/changelogs/20261029173255_release-0-1-9.md.
