# Highlight scroll into view

## Decisions

After rendering with a highlighted option, call scrollIntoView on that option with block nearest so Arrow Up and Arrow Down keep the focused row inside the scrollable list.

## Effects

Stimulus controller scrollHighlightedIntoView runs from render when aria-activedescendant is set. JavaScript behavior test covers the scroll call.

## Next

Shipped in 0.1.7. Run `make release` after the release commit is on a clean tree.

## Source

rfcs/0003-palette-shell.md
