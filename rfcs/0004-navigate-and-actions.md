# RFC 0004: Navigate and actions

- Feature Name: navigate-and-actions
- Type: Standards Track
- Status: Stable
- Created: 2026-10-10
- Author: Andrei Makarov
- Relates: RFC 0002, RFC 0003, RFC 0006

## Summary

Build a navigate catalog from the current ActiveAdmin menu and an allow-listed action catalog from configuration (plus resource DSL compile). Actions carry scope, when, resource, verb, params, help, and optional `if` gates. Page context from the layout decides which member and collection actions appear.

## Motivation

Menu labels and URLs already exist in ActiveAdmin. Requiring hosts to re-register every menu item would duplicate that tree. Free-form actions without an allow-list would let a typo ship a destructive method or miss confirmation. Contextual edit and destroy must see the current record and page action or they appear on the wrong screen.

## Guide-level explanation

Navigate items appear as kind `navigate` with breadcrumb labels joined by ` › `. Global shortcuts go in `config.actions`. Resource DSL `actions :view, :create, :edit, :destroy` and `member` compile into the same list on `reload!` (RFC 0006). On each request the helper emits filtered actions and a `context` object. Operators type `>` to filter actions. `view` enters kind find. `create` accepts optional `name=value` tokens mapped through `params` / `query_key`.

## Reference-level explanation

### Navigate item shape

```text
{ id, kind: "navigate", label, url, method: "get" }
```

`Catalog.navigate` walks `current_menu`, skips items without a URL, and returns `[]` on menu walk errors.

### Action fields

Required after normalize: `id`, `label`. Defaults: `method` `get`, `scope` `global`, `when` `["any"]`.

Allowed methods: `get`, `post`, `put`, `delete`. `post`, `put`, and `delete` require non-empty `confirm` at registration time.

Allowed scopes: `global`, `collection`, `member`. Allowed `when` tokens: `any`, `index`, `show`, `new`, `edit`. Controller actions `create` and `update` gate as `new` and `edit`.

Optional fields: `url` or `path`, `path_args`, `query`, `resource`, `verb`, `params`, `help`, `finder_kind`, `if`.

`params` entries: `name` required; `required` boolean; optional `help`, `query_key`.

`query` values and `url` strings may include `%{record_param}` and `%{resource}`.

### Context object

```text
{ namespace, resource, resource_param, record_param, action, page }
```

`page` is `resource`, `page`, or `other`. Member scope requires `record_param`. Collection scope requires gated action `index`. Member and collection with `resource` require matching `context.resource`.

### `if` gate

When present, a boolean is used as-is; a callable runs in the view via `instance_exec`. False omits the action from the request payload.

### URL resolution

Prefer `url` with interpolation. Else call `view.public_send(path, *path_args)`. Member scope without explicit `path_args` uses `[record_param]` and fails closed when blank. Explicit `path_args: []` allows collection routes with query. Missing helper or URL generation errors yield no URL; items without URL are dropped unless `verb` is `view`.

## Registrar

Public config writer: `Configuration#actions=`. Catalog API: `Catalog.navigate`, `Catalog.actions`. Action verbs in use: `view`, `create`, `edit`, `destroy`, `custom`.

## Drawbacks

Allow-list registration is ceremony. Context gating means the same action id can be absent on another page, which surprises operators who expected a global list.

## Rationale and alternatives

Re-registering menus in the gem config would drift from ActiveAdmin. Shipping every resource action without `scope` / `when` would show destroy on index. Doing nothing leaves only mouse navigation.

## Prior art

ActiveAdmin menu API; Rails path helpers; command palette action modes in editor UIs.

## Unresolved questions

Whether `when` should gain an explicit `other` token for non-CRUD admin actions.

Whether navigate ids should stabilize on something other than `nav-#{item.id}` when ActiveAdmin changes menu item identity.
