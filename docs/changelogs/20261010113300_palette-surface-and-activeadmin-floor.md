## Participants

Andrei Makarov (@amkisko)

## Decisions

Raise the ActiveAdmin dependency floor to `4.0.0.beta23`. Keep a single panel surface in the palette shell; remove filled rounded kind chips so rows do not read as nested cards.

## Effects

`activeadmin-command-palette.gemspec` and README requirements updated. Stimulus row kind label uses typography-only classes. Live-work note records the no card-in-card rule for later theme work. Appraisal and root lockfiles declare `activeadmin (>= 4.0.0.beta23, < 5)` and resolve `4.0.0.beta23`. bundler-audit clean on all four lockfiles. Ruby and JavaScript suites green after the floor and badge class change.

## Source

`docs/issues/20261010113300_palette-surface-and-activeadmin-floor.md`.
