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

- `spec/lib` — unit specs for catalog, compiler, configuration, finder, and helpers
- `spec/requests` — options endpoint contract
- `spec/javascript` — command palette client behavior
- `spec/dummy/` — minimal Rails app for ActiveAdmin-backed specs

## Guidelines

- Test executable behavior and host-facing contracts in this repo.
- Add or update specs before bugfixes; run `make lint && make test` before a PR.
- Coverage threshold: `config/polyrun_coverage.yml`; CI runs a separate `coverage` job with `POLYRUN_COVERAGE=1`.
