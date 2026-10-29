## Participants

Andrei Makarov (@amkisko)

## Decisions

Publish as `activeadmin-command_palette` per RubyGems naming: hyphen for an ActiveAdmin extension, underscore inside `command_palette`. Bundler default require is `activeadmin/command_palette`.

Keep the GitHub repository name `activeadmin_command_palette.rb`. Keep Rails `engine_name`, Stimulus asset paths, and locale file basenames on underscores.

## Effects

Gemspec renamed. Top-level `lib/activeadmin_command_palette.rb` removed; entry is `lib/activeadmin/command_palette.rb` (loads version, library, engine). Version 0.1.5.

## Next

First RubyGems publish under this name is planned as 0.1.6 (see `docs/changelogs/20261010113917_release-0-1-6.md`).

## Source

docs/issues/20261009214600_prepare-gem-for-publishing.md
