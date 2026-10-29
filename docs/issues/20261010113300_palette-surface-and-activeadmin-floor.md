## Participants

Andrei Makarov (@amkisko)

## Decisions

Palette shell keeps one elevated surface (the dialog panel). Inner hierarchy uses dividers, typography, and background highlight only. Nested bordered rounded shadowed blocks (card-in-card) are out of scope for default markup and for future theme hooks.

Kind labels on result rows stay typographic, not chip boxes with their own fill and radius.

Require ActiveAdmin `>= 4.0.0.beta23` (latest 4.x prerelease on RubyGems as of this note). That floor matches hosts on the ActiveAdmin Tailwind CSS v4 build path. Older 4.0 betas through beta22 are no longer in the supported range.

## Effects

Gemspec and README floor raised from `4.0.0.beta13` to `4.0.0.beta23`. Kind badge utilities no longer use rounded filled chip styling.

## Next

Done for styles: gem-owned Tailwind entry at `app/assets/stylesheets/activeadmin_command_palette.css`, exposed as `ActiveAdmin::CommandPalette.tailwind_entry_path`. See `docs/issues/20261012110500_tailwind-entry-and-highlight-scroll.md`. Optional later: semantic class hooks without introducing nested card chrome.

## Source

Conversation on palette customization and Tailwind 4. Relates RFC 0003. `docs/changelogs/20261010113300_palette-surface-and-activeadmin-floor.md`.
## Validation

Commands: `bundle update activeadmin` across root and appraisal gemfiles (resolved `4.0.0.beta23`, already current); `bundle exec bundler-audit check` on each lockfile (No vulnerabilities found); `bundle exec rspec` (44 examples, 0 failures); `make test-javascript` (11 tests, 0 failures); `npx @biomejs/biome@2.3.8 check app/assets/controllers/activeadmin_command_palette/command_palette_controller.js` (clean).
