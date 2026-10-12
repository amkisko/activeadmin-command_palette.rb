## Decisions

RubyGems package name is `activeadmin-command_palette` (hyphen after ActiveAdmin, underscore in `command_palette`) so Bundler default-requires `activeadmin/command_palette`.

Yank `activeadmin-command-palette` 0.1.6. Republish the same version under `activeadmin-command_palette`. Keep Stimulus controller identifiers and `engine_name` unchanged.

## Effects

Gemspec file renamed to `activeadmin-command_palette.gemspec`. `spec.name` set to `activeadmin-command_palette`. README gem badges and registry links updated.

## Next

Yank on RubyGems, `gem build` / `gem push` under the corrected name, refresh appraisal lockfiles.

## Source

docs/changelogs/20261010101900_rename-gem-to-hyphenated.md
CHANGELOG.md 0.1.5 and 0.1.6
