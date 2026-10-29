## Participants

Andrei Makarov (@amkisko)

## Decisions

Start the house RFC process in this repository. Document already-shipped design as Stable Standards Track RFCs so later public contract changes cite numbers instead of README alone.

## Effects

Added `rfcs/` with template, README, id claims, procedural RFC 0001 (Proposed), informational RFC 0002 (Stable), and Stable Standards Track RFCs 0003 through 0006 covering palette shell, navigate and actions, finder protocol, and resource DSL.

## Next

Open `rfc: 0001 rfc process` (and the feature docs PR, or the same PR) for lazy-consensus review through 2026-10-24. Cite `RFC-NNNN` from implementation PRs that change those contracts.

## Source

`.agents/skills/rfc-process`; sibling shape from active_version.rb `rfcs/`; shipped behavior from README, CHANGELOG, and library code under `lib/activeadmin/command_palette` and `app/assets/controllers/activeadmin_command_palette`.
