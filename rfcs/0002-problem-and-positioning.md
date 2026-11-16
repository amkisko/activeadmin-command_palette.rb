# RFC 0002: Problem and positioning

- Feature Name: problem-and-positioning
- Type: Informational
- Status: Stable
- Created: 2026-10-10
- Author: Andrei Makarov
- Relates: RFC 0003, RFC 0004, RFC 0005, RFC 0006

## Summary

Give ActiveAdmin 4 operators a Cmd+K / Ctrl+K command palette for menu navigation, allow-listed actions, and host-registered record finders. The gem does not know host domain models.

## Motivation

ActiveAdmin menus and resource pages grow faster than operators can click through. A keyboard palette that only searches hard-coded model names in the gem would invent a domain the host already owns. Stacking a generic command palette gem that introspects every ActiveRecord class would expose labels, scopes, and destroy paths the admin never registered.

This gem ships the shell, the menu walk, the action allow-list, and a finder protocol. Hosts keep `ActiveAdmin.routes`, register finders or a resource DSL plus `default_finder`, and keep row-level authorization in finders. Options auth follows ActiveAdmin (RFC 0009). Changing options ownership, Stimulus controller identity, action fields, finder result keys, or the resource DSL without a numbered RFC breaks host layouts and initializers.

## Guide-level explanation

Add the gem, keep `ActiveAdmin.routes(self)`, wire layout body data attributes and the palette partial, and register finders or `command_palette` blocks. Operators open the palette with Cmd+K or Ctrl+K, filter navigate items, run `>` actions, and search records through host finders. Built-in UI locales cover English, Finnish, and Swedish.

## Drawbacks

Hosts must wire layout and register finders or a `default_finder`. The gem cannot invent destroy or edit URLs for resources that never opted in. Operators who wanted automatic discovery of every model pay setup work instead.

## Rationale and alternatives

Hard-coding models inside the gem would look smaller and would break every host whose names differ. Auto-walking ActiveRecord would widen the attack and authorization surface. Doing nothing leaves operators hunting menus by mouse. Contract detail is RFC 0003 through RFC 0006.

## Prior art

Editor and launcher command palettes; browser omnibox prefix modes; ActiveAdmin menus and resource DSL. Other ActiveAdmin extensions keep host wiring explicit rather than inventing domain tables.

## Unresolved questions

Whether a future RFC should freeze a public JSON schema for finder results beyond the keys already normalized in RFC 0005.

Whether multi-namespace ActiveAdmin hosts need a separate RFC when more than one palette mount is required.
