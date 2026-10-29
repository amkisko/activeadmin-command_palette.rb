# Engineering audit and release preparation

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Continue on main while preserving the pre-existing uncommitted changes. Do not commit, tag, push, or publish.
- Keep release version 0.1.9 with the 2026-10-29 changelog date.
- Review correctness, executable coverage, workflow triggers and permissions, package boundaries, resource cost, and release confirmation. Re-audit the changed paths after corrections.

## Effects

- Keep navigation available when browser session storage is disabled or full. Catch setItem failures in remember so navigateItem still assigns the URL.
- Treat end-of-input at the release confirmation prompt as rejection. Unit and process-boundary regressions cover EOF, Enter default, y, and n. No publication command was executed against a real registry.
- Restrict test.yml to contents: read and cancel-in-progress concurrency. Third-party actions stay pinned by commit. pull_request remains a trigger.
- After make release hit GHSA-pq4g-8rxf-4g29 on crass 1.0.7, lockfiles move to crass 1.0.8. bundler-audit is clean on root and appraisal gemfiles.
- make test, Biome, RBS validation, RuboCop, 13 JavaScript tests, and the sharded Ruby suite pass under Ruby 4.0.2. Serial rspec: 49 examples, 0 failures.
- The 0.1.9 gem builds and passes Gem::Package#verify: 28160 compressed bytes across 32 packaged paths.
- Controller payload: 25639 bytes raw, 6555 bytes gzip-compressed.
- Version-only cold load: 0.17 CPU seconds, 27721728 bytes peak RSS. Dummy Rails host cold load: 1.30 CPU seconds, 146063360 bytes peak RSS. These are single-machine observations, not co-location budgets.
- Coverage merge: 95.95% lines (497/518). git diff --check passes. RubyGems still lists 0.1.8 as latest.

## Next

- No confirmed correction remains in the reviewed changes. Hosted GitHub Actions and the complete appraisal matrix inside make release were not executed as a publish run.
- Scope limits: production traffic, embedding-host database size, and co-located resource interference were not measured.
- Review and commit, then make release. The command requires a clean worktree and interactive confirmation.

## Source

- AGENTS.md and .agents/skills/engineering-audit/.
- docs/issues/20261029173255_engineering-release-audit.md
- docs/changelogs/20261029173255_release-0-1-9.md
- docs/reviews/20261028_engineering-audit-release-preparation.md (superseded incomplete draft)
