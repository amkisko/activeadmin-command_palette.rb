# Tailwind entry and highlight scroll

## Decisions

Ship a gem-owned Tailwind entry that hosts concatenate into the ActiveAdmin CSS build. Expose it as ActiveAdmin::CommandPalette.tailwind_entry_path. Keep shell class tokens listed there in sync with the palette partial and Stimulus controller.

After rendering with a highlighted option, call scrollIntoView with block nearest so Arrow Up and Arrow Down keep the focused row visible.

## Effects

Hosts no longer need a content-path recipe for gem views or assets. Missing entry tokens would drop palette layout utilities from the admin stylesheet.

## Next

Prepared as 0.1.8 for the install README. Commit a clean tree, then run `make release`. Point hosts at the new version and concatenate the entry in their ActiveAdmin Tailwind build.

## Source

rfcs/0003-palette-shell.md
docs/changelogs/20261012110500_tailwind-entry-and-highlight-scroll.md
