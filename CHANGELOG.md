# CHANGELOG

## Unreleased

## 0.1.6

- Publish as `activeadmin-command_palette` so Bundler requires `activeadmin/command_palette` by default; yank mistaken `activeadmin-command-palette` 0.1.6.
- Require ActiveAdmin 4.0.0.beta23 or newer.
- Keep kind labels on result rows as plain text instead of filled chips inside the panel.
- Send finder queries in CSRF-protected request bodies and combine multi-kind search into one bounded request.
- Refuse executable navigation URLs and cross-origin mutating actions.
- Announce asynchronous search states to assistive technology and preserve fragments in prefilled create links.
- Run JavaScript behavior tests in CI and release checks; reject releases from a dirty Git worktree.
- Finder options may include `detail` and `keywords`; `subtitle` maps to `detail`.
- Navigate crumbs become keywords; local filter matches label, detail, kind, and keywords with substring or fuzzy subsequence.
- Longer query prefixes win; results show a detail line and kind section headers; Enter activates the only remaining item when nothing is highlighted.

## 0.1.5

- Rename the gem to `activeadmin-command_palette` so Bundler loads `activeadmin/command_palette` by default.

## 0.1.4

- Resource DSL: `command_palette` in `ActiveAdmin.register` with `find_by`, `actions`, `create`, and `member`.
- `reload!` compiles resource registrations into actions and finders via optional `default_finder`.
- Run `reload!` from ActiveAdmin `after_load` (not bare `to_prepare`) so compile sees loaded resources.
- Action `if:` (boolean or view-context callable) omits the action from the request payload when false.

## 0.1.3

- Allow `put` with confirm; interpolate `%{record_param}` / `%{resource}` in `url` and `query`.
- Support explicit empty `path_args` for member actions that open collection routes with query.

## 0.1.2

- Contextual actions: `scope`, `when`, `resource`, `verb`, `params`, `help`, `finder_kind`.
- Allow `delete` with confirm; submit via POST `_method=delete`.
- Emit page `context` for member/collection gating; include view actions without a URL.
- Client: filter by context, view enters kind find, create merges optional query params and shows help.

## 0.1.1

- Clear selection during debounce, abort stale fetches, and show loading, error, and sign-in states instead of empty matches.
- Require non-empty `confirm` for POST actions; allow only `get` and `post`.
- Keep recent items in `sessionStorage` for navigate/action destinations only.
- Expose combobox/`aria-activedescendant` state on the palette input.

## 0.1.0

- Initial local package: Cmd+K palette shell, menu catalog, allow-listed actions, host finder protocol, and JSON options endpoint.
- Locale files for English, Finnish, and Swedish.
