# Rails 8.1.4.1 and Ransack advisory bump

## Dependency

- rails (appraisal / lockfile pin): was 8.1.4, now 8.1.4.1; Appraisals floor `>= 8.1.4.1`
- rails 7.2 appraisal: stayed on 7.2.4 (latest 7.2 line)
- ransack (transitive via activeadmin): was 6.0.0, now 6.1.0 (root / rails8) and 6.0.1 (rails72)

## Symptom

`make release` failed at
`BUNDLE_GEMFILE=gemfiles/rails72.gemfile bundle exec bundler-audit check --update`
with multiple Rails GHSA advisories on 8.1.4 and Ransack GHSA-58rx-96gf-w92x on 6.0.0.

## Evidence

- bundler-audit against ruby-advisory-db commit 98dc44b (2026-11-16)
- Solutions named `>= 8.1.4.1` (and `~> 8.0.5, >= 8.0.5.2`) for Rails gems and
  `>= 6.0.1` for ransack
- After lockfile bump: all four graphs report `No vulnerabilities found`

## Suggested fix

Upgrade appraisal and root lockfiles to Rails 8.1.4.1 and Ransack >= 6.0.1.
Keep the gemspec rails floor at `>= 7.2`; hosts supply their own Rails patch level.

## Effects

- Appraisals and rails8 gemfiles require `>= 8.1.4.1`
- Gemfile.lock and rails8 appraisal locks pin rails 8.1.4.1 and ransack 6.1.0
- rails72 lock pins ransack 6.0.1; rails remains 7.2.4

## Next

Re-run `make release` after committing the lockfile bump.

## Source

- https://github.com/rails/rails/security/advisories
- https://github.com/activerecord-hackery/ransack/security/advisories/GHSA-58rx-96gf-w92x
- usr/bin/release.rb bundler-audit step
