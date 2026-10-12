import { Controller } from "@hotwired/stimulus";

const RECENT_KEY = "activeadmin-command-palette-recent";
const RECENT_LIMIT = 8;
const LIST_LIMIT = 40;
const RECORD_LIMIT = 20;
const DEBOUNCE_MS = 200;
const REQUEST_TIMEOUT_MS = 5_000;
const STATIC_KINDS = new Set(["navigate", "action"]);

export default class extends Controller {
  static targets = ["dialog", "query", "list", "panel", "shortcut", "announcer"];
  static values = {
    navigate: Array,
    actions: Array,
    context: Object,
    optionsUrl: String,
    csrf: String,
    prefixes: Object,
    kinds: Array,
    minQueryLength: { type: Number, default: 2 },
    requestTimeout: { type: Number, default: REQUEST_TIMEOUT_MS },
    empty: { type: String, default: "No matches" },
    loading: { type: String, default: "Searching…" },
    error: { type: String, default: "Search failed. Try again." },
    unauthorized: {
      type: String,
      default: "Session expired. Sign in again to keep searching.",
    },
    forbidden: {
      type: String,
      default: "You do not have permission to search these records.",
    },
    required: { type: String, default: "required" },
    optional: { type: String, default: "optional" },
    helpItems: Array,
    signInPath: { type: String, default: "/user/sign_in" },
  };

  connect() {
    this.open = false;
    this.highlightedIndex = -1;
    this.visibleItems = [];
    this.status = null;
    this.announceStatus();
    this.queryGeneration = 0;
    this.abortController = null;
    this.timeout = null;
    this.previousActive = null;
    this.forcedKind = null;
    this.boundKeydown = this.globalKeydown.bind(this);
    document.addEventListener("keydown", this.boundKeydown);
    this.updateShortcutLabel();
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown);
    clearTimeout(this.timeout);
    this.abortInFlight();
  }

  updateShortcutLabel() {
    if (!this.hasShortcutTarget) return;
    const mac = /Mac|iPhone|iPad|iPod/.test(navigator.platform || "");
    this.shortcutTarget.textContent = mac ? "⌘K" : "Ctrl+K";
  }

  globalKeydown(event) {
    const metaK = (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k";
    if (metaK) {
      event.preventDefault();
      this.toggle();
      return;
    }

    if (event.key === "Escape" && this.open) {
      event.preventDefault();
      this.close();
    }
  }

  toggle() {
    if (this.open) {
      this.close();
    } else {
      this.show();
    }
  }

  show() {
    this.open = true;
    this.forcedKind = null;
    this.previousActive = document.activeElement;
    this.dialogTarget.classList.remove("hidden");
    this.queryTarget.value = "";
    this.queryTarget.setAttribute("aria-expanded", "true");
    this.refresh();
    this.queryTarget.focus();
  }

  close() {
    this.open = false;
    this.forcedKind = null;
    clearTimeout(this.timeout);
    this.abortInFlight();
    this.dialogTarget.classList.add("hidden");
    this.queryTarget.value = "";
    this.queryTarget.setAttribute("aria-expanded", "false");
    this.queryTarget.removeAttribute("aria-activedescendant");
    this.listTarget.replaceChildren();
    this.visibleItems = [];
    this.highlightedIndex = -1;
    this.status = null;
    if (this.previousActive && typeof this.previousActive.focus === "function") {
      this.previousActive.focus();
    }
    this.previousActive = null;
  }

  onInput() {
    clearTimeout(this.timeout);
    const mode = this.parseMode(this.queryTarget.value);
    if (mode.name === "find" || mode.name === "kind" || mode.name === "actions") {
      if (mode.name === "find" || mode.name === "kind") {
        this.markPendingSearch();
      }
      this.timeout = setTimeout(() => this.refresh(), DEBOUNCE_MS);
    } else {
      this.refresh();
    }
  }

  markPendingSearch() {
    this.abortInFlight();
    this.visibleItems = [];
    this.highlightedIndex = -1;
    this.status = "loading";
    this.render();
  }

  abortInFlight() {
    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    }
  }

  onKeydown(event) {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      this.moveHighlight(1);
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      this.moveHighlight(-1);
    } else if (event.key === "Enter") {
      event.preventDefault();
      this.activateHighlighted();
    }
  }

  onDialogKeydown(event) {
    if (event.key !== "Tab" || !this.open) return;

    const candidates = [
      this.queryTarget,
      ...this.dialogTarget.querySelectorAll(
        'a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])'
      ),
    ];
    const focusable = [...new Set(candidates)];
    if (focusable.length === 0) return;

    const currentIndex = focusable.indexOf(document.activeElement);
    const direction = event.shiftKey ? -1 : 1;
    const nextIndex = (currentIndex + direction + focusable.length) % focusable.length;
    event.preventDefault();
    focusable[nextIndex].focus();
  }

  parseMode(raw) {
    const value = raw.toString();
    if (value.startsWith(">") || value.startsWith("?")) {
      this.forcedKind = null;
    }

    if (this.forcedKind) {
      return {
        name: "kind",
        kind: this.forcedKind,
        query: value.trim(),
      };
    }

    if (value.startsWith(">")) {
      return { name: "actions", query: value.slice(1).trim() };
    }
    if (value.startsWith("?")) {
      return { name: "help", query: value.slice(1).trim() };
    }

    const prefixes = this.hasPrefixesValue ? this.prefixesValue : {};
    const orderedPrefixes = Object.entries(prefixes).sort(
      (left, right) => right[0].length - left[0].length
    );
    for (const [prefix, kind] of orderedPrefixes) {
      if (prefix && value.startsWith(prefix)) {
        return {
          name: "kind",
          kind,
          query: value.slice(prefix.length).trim(),
        };
      }
    }

    return { name: "find", query: value.trim() };
  }

  contextObject() {
    return this.hasContextValue ? this.contextValue || {} : {};
  }

  contextFilteredActions() {
    const context = this.contextObject();
    return (this.actionsValue || []).filter((action) => this.actionMatchesContext(action, context));
  }

  actionMatchesContext(action, context) {
    const scope = (action.scope || "global").toString();
    const whenList = Array.isArray(action.when)
      ? action.when.map(String)
      : [String(action.when || "any")];
    const rawAction = (context.action || "other").toString();
    const actionName = rawAction === "create" ? "new" : rawAction === "update" ? "edit" : rawAction;

    if (scope === "member" && !context.record_param) return false;
    if (scope === "collection" && actionName !== "index") return false;
    if (
      !whenList.includes("any") &&
      !whenList.includes(actionName) &&
      !whenList.includes(rawAction)
    ) {
      return false;
    }
    if ((scope === "member" || scope === "collection") && action.resource) {
      if (String(context.resource || "") !== String(action.resource)) return false;
    }
    return true;
  }

  findActionForQuery(query) {
    const trimmed = (query || "").trim();
    if (!trimmed) return null;
    const lower = trimmed.toLowerCase();
    let best = null;
    for (const action of this.contextFilteredActions()) {
      const label = (action.label || "").trim();
      const labelLower = label.toLowerCase();
      if (lower === labelLower || lower.startsWith(`${labelLower} `)) {
        if (!best || label.length > (best.action.label || "").length) {
          best = {
            action,
            remainder: trimmed.slice(label.length).trim(),
          };
        }
      }
    }
    return best;
  }

  actionsForQuery(query) {
    const actions = this.contextFilteredActions();
    const match = this.findActionForQuery(query);
    if (match) return [match.action];
    return this.filterLocal(actions, query);
  }

  async refresh() {
    const generation = ++this.queryGeneration;
    this.abortInFlight();
    this.abortController = new AbortController();
    const signal = this.abortController.signal;

    const mode = this.parseMode(this.queryTarget.value);
    let items = [];
    let status = null;

    try {
      if (mode.name === "help") {
        items = this.helpItemsValue || [];
      } else if (mode.name === "actions") {
        items = this.actionsForQuery(mode.query);
        const match = this.findActionForQuery(mode.query);
        if (match?.action?.verb === "view" && match.remainder.length >= this.minimumQueryLength()) {
          const result = await this.fetchRecords(match.action.finder_kind, match.remainder, signal);
          if (result.aborted) return;
          if (result.error) {
            status = result.error;
          } else {
            items = this.mergeUnique(items, result.items);
          }
        }
        if (!mode.query) {
          items = this.mergeUnique(this.recentItems("action"), items);
        }
      } else if (mode.name === "kind") {
        const result = await this.fetchRecords(mode.kind, mode.query, signal);
        if (result.aborted) return;
        if (result.error) {
          status = result.error;
          items = [];
        } else {
          items = result.items;
        }
      } else {
        const navigate = this.filterLocal(this.navigateValue, mode.query);
        const recent = mode.query ? [] : this.recentItems();
        let records = [];
        if (mode.query.length >= this.minimumQueryLength()) {
          const result = await this.fetchAllRecords(mode.query, signal);
          if (result.aborted) return;
          if (result.error) {
            status = result.error;
          } else {
            records = result.items;
          }
        }
        items = this.mergeUnique(recent, navigate, records);
      }
    } catch (_error) {
      if (signal.aborted || generation !== this.queryGeneration) return;
      status = "error";
      items = this.filterLocal(
        this.mergeUnique(this.navigateValue, this.contextFilteredActions()),
        this.parseMode(this.queryTarget.value).query
      );
    }

    if (generation !== this.queryGeneration) return;

    this.status = status;
    this.visibleItems = items.slice(0, LIST_LIMIT);
    this.highlightedIndex = this.visibleItems.length > 0 ? 0 : -1;
    this.render();
  }

  async fetchAllRecords(query, signal) {
    const kinds = this.hasKindsValue ? this.kindsValue : [];
    if (!kinds.length) return { items: [] };

    const result = await this.fetchOptions({ kinds, q: query }, signal);
    if (result.items) result.items = result.items.slice(0, RECORD_LIMIT);
    return result;
  }

  async fetchRecords(kind, query, signal) {
    if (!query || query.length < this.minimumQueryLength()) return { items: [] };
    if (!this.optionsUrlValue) return { items: [] };

    return this.fetchOptions({ kind, q: query }, signal);
  }

  async fetchOptions(payload, signal) {
    const requestController = new AbortController();
    let timedOut = false;
    const abortRequest = () => requestController.abort();
    if (signal?.aborted) return { aborted: true };
    signal?.addEventListener("abort", abortRequest, { once: true });
    const requestTimeout = setTimeout(() => {
      timedOut = true;
      requestController.abort();
    }, this.requestTimeoutMilliseconds());

    try {
      const response = await fetch(this.optionsUrlValue, {
        body: JSON.stringify(payload),
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfValue,
        },
        credentials: "same-origin",
        method: "POST",
        signal: requestController.signal,
      });
      if (response.status === 401) return { error: "unauthorized" };
      if (response.status === 403) return { error: "forbidden" };
      if (!response.ok) return { error: "error" };
      const items = await response.json();
      if (!Array.isArray(items)) return { error: "error" };
      return {
        items: items.map((item) => ({
          ...item,
          kind: item.kind || payload.kind,
          method: item.method || "get",
        })),
      };
    } catch (error) {
      if (signal?.aborted) return { aborted: true };
      if (timedOut) return { error: "error" };
      if (error?.name === "AbortError") return { aborted: true };
      return { error: "error" };
    } finally {
      clearTimeout(requestTimeout);
      signal?.removeEventListener("abort", abortRequest);
    }
  }

  minimumQueryLength() {
    const value = this.hasMinQueryLengthValue ? Number(this.minQueryLengthValue) : 2;
    return Number.isFinite(value) && value >= 0 ? value : 2;
  }

  requestTimeoutMilliseconds() {
    const value = this.hasRequestTimeoutValue
      ? Number(this.requestTimeoutValue)
      : REQUEST_TIMEOUT_MS;
    return Number.isFinite(value) && value > 0 ? value : REQUEST_TIMEOUT_MS;
  }

  filterLocal(items, query) {
    if (!query) return items || [];
    const needle = query.toLowerCase();
    return (items || []).filter((item) => this.itemMatchesQuery(item, needle));
  }

  itemMatchesQuery(item, needle) {
    const fields = [item.label, item.detail, item.kind, ...(item.keywords || [])];
    return fields.some((field) => this.matchesText(field, needle));
  }

  matchesText(haystack, needle) {
    if (!needle) return true;
    const text = String(haystack || "").toLowerCase();
    if (!text) return false;
    if (text.includes(needle)) return true;

    let index = 0;
    for (const character of text) {
      if (character === needle[index]) index += 1;
      if (index === needle.length) return true;
    }
    return false;
  }

  mergeUnique(...groups) {
    const seen = new Set();
    const result = [];
    groups.flat().forEach((item) => {
      if (!item) return;
      const key = `${item.kind}:${item.id || item.url}`;
      if (seen.has(key)) return;
      seen.add(key);
      result.push(item);
    });
    return result;
  }

  recentItems(kind = null) {
    try {
      const raw = JSON.parse(sessionStorage.getItem(RECENT_KEY) || "[]");
      const currentItems = this.mergeUnique(
        this.navigateValue || [],
        this.contextFilteredActions()
      ).filter((item) => {
        if (!item?.url || !STATIC_KINDS.has(item.kind)) return false;
        if ((item.method || "get").toLowerCase() !== "get") return false;
        return (item.scope || "global") !== "member";
      });
      const currentByKey = new Map(
        currentItems.map((item) => [`${item.kind}:${item.id || item.url}`, item])
      );

      return raw.flatMap((item) => {
        if (!STATIC_KINDS.has(item.kind)) return [];
        if (kind && item.kind !== kind) return [];
        const current = currentByKey.get(`${item.kind}:${item.id || item.url}`);
        return current ? [current] : [];
      });
    } catch (_error) {
      return [];
    }
  }

  remember(item) {
    if (!item?.url || !STATIC_KINDS.has(item.kind)) return;
    if ((item.method || "get").toLowerCase() !== "get") return;
    if ((item.scope || "global") === "member") return;
    const next = this.mergeUnique([{ ...item, id: item.id || item.url }], this.recentItems()).slice(
      0,
      RECENT_LIMIT
    );
    sessionStorage.setItem(RECENT_KEY, JSON.stringify(next));
  }

  render() {
    this.listTarget.replaceChildren();
    this.announceStatus();

    if (this.status === "loading" && this.visibleItems.length === 0) {
      this.appendStatusRow(this.loadingValue);
      this.queryTarget.removeAttribute("aria-activedescendant");
      return;
    }

    let previousKind = null;
    this.visibleItems.forEach((item, index) => {
      const kind = item.kind || "go";
      if (kind !== previousKind) {
        this.appendSectionHeader(kind);
        previousKind = kind;
      }

      const row = document.createElement("li");
      const optionId = `activeadmin-command-palette-option-${index}`;
      row.id = optionId;
      row.className = this.rowClass(index);
      row.dataset.index = String(index);
      row.dataset.action = "mousedown->activeadmin-command-palette--command-palette#activateRow";
      row.setAttribute("role", "option");
      row.setAttribute("aria-selected", index === this.highlightedIndex ? "true" : "false");

      const badge = document.createElement("span");
      badge.className =
        "me-2 shrink-0 text-[10px] uppercase tracking-wide text-gray-500 dark:text-gray-400";
      badge.textContent = kind;

      const text = document.createElement("span");
      text.className = "min-w-0 flex flex-col";

      const label = document.createElement("span");
      label.textContent = item.label;
      text.appendChild(label);

      if (item.detail) {
        const detail = document.createElement("span");
        detail.className = "text-xs text-gray-500 dark:text-gray-400";
        detail.textContent = item.detail;
        text.appendChild(detail);
      }

      row.append(badge, text);
      this.listTarget.appendChild(row);
    });

    if (this.status === "unauthorized") {
      this.appendStatusRow(this.unauthorizedValue, this.signInPathValue);
    } else if (this.status === "forbidden") {
      this.appendStatusRow(this.forbiddenValue);
    } else if (this.status === "error") {
      this.appendStatusRow(this.errorValue);
    } else if (this.status === "loading") {
      this.appendStatusRow(this.loadingValue);
    } else if (this.visibleItems.length === 0) {
      this.appendStatusRow(this.emptyValue);
    }

    if (this.highlightedIndex >= 0 && this.visibleItems.length > 0) {
      this.queryTarget.setAttribute(
        "aria-activedescendant",
        `activeadmin-command-palette-option-${this.highlightedIndex}`
      );
    } else {
      this.queryTarget.removeAttribute("aria-activedescendant");
    }
  }

  appendSectionHeader(kind) {
    const header = document.createElement("li");
    header.className =
      "px-3 pt-2 pb-1 text-[10px] font-semibold uppercase tracking-wide text-gray-400 dark:text-gray-500";
    header.setAttribute("role", "presentation");
    header.textContent = kind;
    this.listTarget.appendChild(header);
  }

  appendStatusRow(text, href = null) {
    const empty = document.createElement("li");
    empty.className = "px-3 py-3 text-sm text-gray-500 dark:text-gray-400";
    empty.setAttribute("role", "presentation");
    if (href) {
      const link = document.createElement("a");
      link.href = href;
      link.className = "underline";
      link.textContent = text;
      empty.appendChild(link);
    } else {
      empty.textContent = text;
    }
    this.listTarget.appendChild(empty);
  }

  announceStatus() {
    if (!this.hasAnnouncerTarget) return;

    const messages = {
      loading: this.loadingValue,
      unauthorized: this.unauthorizedValue,
      forbidden: this.forbiddenValue,
      error: this.errorValue,
    };
    const message =
      messages[this.status] ||
      (!this.status && this.visibleItems?.length === 0 ? this.emptyValue : "");
    this.announcerTarget.textContent = message;
    this.queryTarget?.setAttribute("aria-busy", this.status === "loading" ? "true" : "false");
  }

  rowClass(index) {
    const base =
      "flex cursor-pointer items-center px-3 py-2 text-sm text-gray-900 dark:text-gray-100 hover:bg-gray-100 dark:hover:bg-gray-800";
    return index === this.highlightedIndex ? `${base} bg-gray-100 dark:bg-gray-800` : base;
  }

  moveHighlight(delta) {
    if (this.visibleItems.length === 0) return;
    this.highlightedIndex =
      (this.highlightedIndex + delta + this.visibleItems.length) % this.visibleItems.length;
    this.render();
  }

  activateRow(event) {
    event.preventDefault();
    const index = Number(event.currentTarget.dataset.index);
    this.highlightedIndex = index;
    this.activateHighlighted();
  }

  activateHighlighted() {
    let index = this.highlightedIndex;
    if (index < 0 && this.visibleItems.length === 1) {
      index = 0;
    }
    const item = this.visibleItems[index];
    if (!item || item.kind === "help") return;

    if (item.kind === "action") {
      const mode = this.parseMode(this.queryTarget.value);
      const remainder =
        mode.name === "actions" ? this.findActionForQuery(mode.query)?.remainder || "" : "";
      this.activateAction(item, remainder);
      return;
    }

    if (!item.url) return;
    this.navigateItem(item);
  }

  activateAction(action, remainder) {
    const verb = (action.verb || "").toString();

    if (verb === "view") {
      if (!action.finder_kind) return;
      this.enterKindFind(action.finder_kind, remainder);
      return;
    }

    if (verb === "create") {
      const parsed = this.parseActionParams(remainder);
      const missing = (action.params || []).filter(
        (param) => param.required && (parsed[param.name] == null || parsed[param.name] === "")
      );
      if (missing.length || (!action.url && remainder)) {
        this.showActionHelp(action);
        return;
      }
      const url = this.applyQueryParams(action.url, action, parsed);
      if (!url) {
        this.showActionHelp(action);
        return;
      }
      const safeUrl = this.safeNavigationUrl(url);
      if (!safeUrl) {
        this.showNavigationError();
        return;
      }
      this.remember(action);
      this.close();
      window.location.assign(safeUrl);
      return;
    }

    if (!action.url) {
      if (action.help || (action.params || []).length) {
        this.showActionHelp(action);
      }
      return;
    }

    this.navigateItem(action);
  }

  enterKindFind(kind, query = "") {
    this.forcedKind = kind;
    this.queryTarget.value = query || "";
    this.refresh();
    this.queryTarget.focus();
  }

  showActionHelp(action) {
    const rows = [];
    if (action.help) {
      rows.push({
        id: `${action.id}-help`,
        kind: "help",
        label: action.help,
        url: null,
      });
    }
    (action.params || []).forEach((param) => {
      const required = param.required ? this.requiredValue : this.optionalValue;
      rows.push({
        id: `${action.id}-param-${param.name}`,
        kind: "help",
        label: `${param.name}= (${required})${param.help ? ` — ${param.help}` : ""}`,
        url: null,
      });
    });
    this.status = null;
    this.visibleItems = rows.slice(0, LIST_LIMIT);
    this.highlightedIndex = this.visibleItems.length > 0 ? 0 : -1;
    this.render();
  }

  parseActionParams(remainder) {
    const result = {};
    String(remainder || "")
      .split(/\s+/)
      .filter(Boolean)
      .forEach((token) => {
        const eq = token.indexOf("=");
        if (eq <= 0) return;
        result[token.slice(0, eq)] = token.slice(eq + 1);
      });
    return result;
  }

  applyQueryParams(url, action, parsed) {
    if (!url) return null;
    const search = new URLSearchParams();
    (action.params || []).forEach((param) => {
      const value = parsed[param.name];
      if (value == null || value === "") return;
      search.append(param.query_key || param.name, value);
    });
    const qs = search.toString();
    if (!qs) return url;
    const fragmentIndex = url.indexOf("#");
    const base = fragmentIndex >= 0 ? url.slice(0, fragmentIndex) : url;
    const fragment = fragmentIndex >= 0 ? url.slice(fragmentIndex) : "";
    const separator = base.includes("?") ? "&" : "?";
    return `${base}${separator}${qs}${fragment}`;
  }

  navigateItem(item) {
    const method = (item.method || "get").toLowerCase();
    const mutating = method === "post" || method === "put" || method === "delete";
    const safeUrl = this.safeNavigationUrl(item.url, { sameOrigin: mutating });
    if (!safeUrl) {
      this.showNavigationError();
      return;
    }
    if (mutating) {
      if (!item.confirm) return;
      if (!window.confirm(item.confirm)) return;
      this.remember(item);
      this.close();
      this.submitMethod(safeUrl, method);
      return;
    }

    this.remember(item);
    this.close();
    window.location.assign(safeUrl);
  }

  safeNavigationUrl(url, { sameOrigin = false } = {}) {
    if (!url) return null;

    try {
      const resolved = new URL(url, window.location.href);
      if (resolved.protocol !== "http:" && resolved.protocol !== "https:") return null;
      if (sameOrigin && resolved.origin !== window.location.origin) return null;
      return url;
    } catch (_error) {
      return null;
    }
  }

  showNavigationError() {
    this.status = "error";
    this.render();
  }

  submitMethod(url, method) {
    const form = document.createElement("form");
    form.method = "post";
    form.action = url;
    form.style.display = "none";

    const csrf = document.createElement("input");
    csrf.type = "hidden";
    csrf.name = "authenticity_token";
    csrf.value = this.csrfValue;
    form.appendChild(csrf);

    if (method !== "post") {
      const methodInput = document.createElement("input");
      methodInput.type = "hidden";
      methodInput.name = "_method";
      methodInput.value = method;
      form.appendChild(methodInput);
    }

    document.body.appendChild(form);
    form.submit();
  }
}
