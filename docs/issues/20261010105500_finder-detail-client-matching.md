## Participants

## Decisions

Ship Proposed RFC 0007 in this repository: optional finder `detail` / `keywords`, longest-prefix matching, richer local match and detail rows, single-item Enter, navigate crumb keywords, and README guidance for host finder ranking and related admin search surfaces.

Reject for this pass: GraphQL inside the gem, automatic filter introspection, frecency, and auto-discovering every resource as searchable.

## Effects

Implemented Finder and Catalog contract pieces, Stimulus matching and rendering, README host recipe, Unreleased CHANGELOG bullets, and engineering changelog note.

## Next

Open `rfc: 0007 finder detail and client matching` for lazy-consensus through 2026-10-24. Release notes for this work sit in 0.1.6; publish with `make release` when the tree is committed and green.

## Validation

Commands: `bundle exec rspec spec/lib/activeadmin/command_palette/finder_spec.rb spec/lib/activeadmin/command_palette/catalog_spec.rb spec/requests/command_palette_options_spec.rb` (19 examples, 0 failures); `bundle exec rspec` (37 examples, 0 failures); `npx @biomejs/biome@2.3.8 check app/assets/controllers/activeadmin_command_palette/command_palette_controller.js` (clean).

## Source

RFC 0007. Relates RFC 0003, RFC 0004, RFC 0005.
