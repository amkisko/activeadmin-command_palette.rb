# crass CSS sanitizer bypass

## Dependency

- Name: crass
- Constraint: transitive via loofah (`~> 1.0.2`)
- Lock entries before: `crass (1.0.7)` in `Gemfile.lock` and `gemfiles/{rails72,rails8ruby34,rails8ruby4}.gemfile.lock`
- Lock entries after: `crass (1.0.8)` in the same files

## Symptom

`make release` failed on `BUNDLE_GEMFILE=gemfiles/rails72.gemfile bundle exec bundler-audit check --update` with GHSA-pq4g-8rxf-4g29: incorrect tokenization of bad URLs enables CSS sanitizer bypass.

## Evidence

- bundler-audit report: crass 1.0.7, solution update to `>= 1.0.8`
- Advisory: https://github.com/rgrove/crass/security/advisories/GHSA-pq4g-8rxf-4g29
- After `bundle update crass` on root and appraisal lockfiles, all four `bundler-audit check` runs reported no vulnerabilities

## Suggested fix

Upgrade the locked transitive gem to 1.0.8. No direct gemspec pin required while loofah keeps `~> 1.0.2`.

## Next

Done for this repository. Hosts that pin older lockfiles still need their own update.

## Source

- GHSA-pq4g-8rxf-4g29
- usr/bin/release.rb appraisal audit loop
- docs/issues/20261029173255_engineering-release-audit.md
