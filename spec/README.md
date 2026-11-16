# Testing

## Commands

Full suite (matches CI: parallel shards via Polyrun):

```bash
make test
```

Lint (RuboCop and RBS):

```bash
make lint
```

JavaScript behavior:

```bash
make test-javascript
```

Focused runs:

```bash
bundle exec rspec spec/
```

See `polyrun.yml`.

## Layout

- `spec/lib` - unit specs for catalog, compiler, configuration, finder, and helpers
- `spec/requests` - options endpoint contract and admin GraphQL coexistence
- `spec/system` - browser e2e for palette UI and admin GraphQL coexistence
- `spec/javascript` - command palette client behavior
- `spec/dummy/` - minimal Rails app for ActiveAdmin-backed specs

## System specs (browser)

Pin the CLI with `.playwright-version` (must match the Ruby client). Install Chromium once:

```bash
PLAYWRIGHT_VERSION=$(tr -d '[:space:]' < .playwright-version)
npx -y "playwright@${PLAYWRIGHT_VERSION}" install chromium
```

Driver registration lives in `spec/support/playwright.rb` (`:railsfi`). Examples marked `type: :system` get `slow: true` for Polyrun. Skip when the browser CLI is missing.

Optional: `HEADFUL=1`, `CAPYBARA_MAX_WAIT`, `PLAYWRIGHT_CLI`, `BROWSER`.

## Guidelines

- Test executable behavior and host-facing contracts in this repo.
- System specs are mandatory for palette UI and browser-side options fetch.
- Add or update specs before bugfixes; run `make lint && make test` before a PR.
- Coverage threshold: `config/polyrun_coverage.yml`; CI runs a separate `coverage` job with `POLYRUN_COVERAGE=1`.
