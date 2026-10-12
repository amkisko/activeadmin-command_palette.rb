## Participants

## Decisions

Extract the package from the host path gem into amkisko/activeadmin_command_palette.rb with the same release tooling as other ActiveAdmin gems: Appraisals, Polyrun, Makefile, usr/bin/release.rb, GitHub Actions, and pray-managed community files.

Gem name on RubyGems is `activeadmin-command_palette` (hyphen extension naming). Repository directory stays `activeadmin_command_palette.rb`.

## Effects

Repository scaffold and dummy-app specs prepared for local validation before first RubyGems publish.

Gem renamed from `activeadmin_command_palette` to `activeadmin-command_palette` before first publish (see docs/changelogs/20261010101900_rename-gem-to-hyphenated.md).

## Next

Initialize git and open the GitHub repository if still needed. Commit a clean tree. Run make test across appraisals, then make release for 0.1.6.

## Source

Host path package under gems/activeadmin_command_palette in the consuming Rails app.

docs/changelogs/20261010101900_rename-gem-to-hyphenated.md
