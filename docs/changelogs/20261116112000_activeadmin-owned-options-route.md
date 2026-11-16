# ActiveAdmin-owned options route

## Participants

Andrei Makarov

## Decisions

Move default options ownership under ActiveAdmin.routes and PageController auth
(RFC 0009). Keep an explicit mount escape hatch.

## Effects

- Default install: no palette `mount` in host `routes.rb`.
- Helper prefers `admin_command_palette_options_path`.
- `authorize_with` is an optional override of ActiveAdmin `Auth::READ`.
- CHANGELOG Unreleased lists the contract change.

## Next

Folded into release 0.2.0 (docs/changelogs/20261116131700_release-0-2-0.md).
