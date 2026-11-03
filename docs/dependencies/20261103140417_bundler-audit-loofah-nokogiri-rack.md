# bundler-audit: loofah, nokogiri, rack, rails-html-sanitizer, sqlite3

## Dependency

- Name: loofah, nokogiri, rack, rails-html-sanitizer, sqlite3
- Constraint: transitive via Rails / Action View for the first four; sqlite3 is a development dependency (`>= 2.10.2` after this fix)
- Lock entries before: loofah 2.25.2, nokogiri 1.19.4, rack 3.2.7, rails-html-sanitizer 1.7.1, sqlite3 2.9.6 in `Gemfile.lock` and `gemfiles/{rails72,rails8ruby34,rails8ruby4}.gemfile.lock`
- Lock entries after: loofah 2.25.3, nokogiri 1.19.7, rack 3.2.8, rails-html-sanitizer 1.7.2, sqlite3 2.10.2 in the same files

## Symptom

`make release` failed on `BUNDLE_GEMFILE=gemfiles/rails72.gemfile bundle exec bundler-audit check --update` with multiple GHSA advisories for the packages above.

## Evidence

- bundler-audit solutions: loofah `>= 2.25.3`, nokogiri `>= 1.19.5`, rack `>= 3.2.8`, rails-html-sanitizer `>= 1.7.2`, sqlite3 `>= 2.10.2`
- Advisories observed in the release log include GHSA-345x-3rq2-jfrm, GHSA-h6v6-rg66-fqj4, GHSA-3w22-6jfg-527w, GHSA-5v64-555j-wjxm, GHSA-cpgf-5mjf-73p7, GHSA-4fqr-96q8-xrfx, and related companion IDs for the same package floors
- After `bundle update loofah nokogiri rack rails-html-sanitizer sqlite3` on root and appraisal lockfiles, all four `bundler-audit check` runs reported no vulnerabilities

## Suggested fix

Upgrade the locked gems to the advisory floors. Raise the gemspec development dependency on sqlite3 to `>= 2.10.2`.

## Next

Done for this repository. Commit the lockfile and gemspec changes, then re-run `make release`.

## Source

- Terminal release failure 2026-11-03 (bundler-audit on rails72 appraisal)
- usr/bin/release.rb appraisal audit loop
- activeadmin-command_palette.gemspec
