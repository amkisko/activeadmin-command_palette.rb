import assert from "node:assert/strict";
import { afterEach, test } from "node:test";

import CommandPaletteController from "../../app/assets/controllers/activeadmin_command_palette/command_palette_controller.js";

const originalDocument = globalThis.document;
const originalFetch = globalThis.fetch;
const originalSessionStorage = globalThis.sessionStorage;
const originalWindow = globalThis.window;

afterEach(() => {
  globalThis.document = originalDocument;
  globalThis.fetch = originalFetch;
  globalThis.sessionStorage = originalSessionStorage;
  globalThis.window = originalWindow;
});

function buildController(overrides = {}) {
  return Object.assign(new CommandPaletteController(), {
    actionsValue: [],
    csrfValue: "csrf-token",
    hasContextValue: true,
    hasKindsValue: true,
    hasMinQueryLengthValue: true,
    hasRequestTimeoutValue: true,
    kindsValue: [],
    minQueryLengthValue: 2,
    navigateValue: [],
    optionsUrlValue: "/admin/command_palette/options",
    requestTimeoutValue: 5_000,
    ...overrides,
  });
}

test("sends record searches in a CSRF-protected request body", async () => {
  const controller = buildController({ minQueryLengthValue: 1 });
  let requestedUrl = null;
  let requestedOptions = null;
  globalThis.fetch = async (url, options) => {
    requestedUrl = url;
    requestedOptions = options;
    return { json: async () => [], ok: true, status: 200 };
  };

  await controller.fetchRecords("user", "a", new AbortController().signal);

  assert.equal(requestedUrl, "/admin/command_palette/options");
  assert.equal(requestedOptions.method, "POST");
  assert.equal(requestedOptions.headers["X-CSRF-Token"], controller.csrfValue);
  assert.deepEqual(JSON.parse(requestedOptions.body), { kind: "user", q: "a" });
});

test("distinguishes authentication and authorization failures", async () => {
  const controller = buildController();
  const statuses = [401, 403];
  globalThis.fetch = async () => ({ ok: false, status: statuses.shift() });

  assert.deepEqual(await controller.fetchRecords("user", "alpha", new AbortController().signal), {
    error: "unauthorized",
  });
  assert.deepEqual(await controller.fetchRecords("user", "alpha", new AbortController().signal), {
    error: "forbidden",
  });
});

test("renders an authorization failure without a sign-in link", () => {
  const controller = buildController({
    forbiddenValue: "Not allowed",
    listTarget: { replaceChildren() {} },
    queryTarget: { removeAttribute() {} },
    status: "forbidden",
    visibleItems: [],
  });
  let statusRow;
  controller.appendStatusRow = (...arguments_) => {
    statusRow = arguments_;
  };

  controller.render();

  assert.deepEqual(statusRow, ["Not allowed"]);
});

test("combines record kinds into one request", async () => {
  const controller = buildController({
    kindsValue: Array.from({ length: 10 }, (_, index) => `kind-${index}`),
  });
  let payload;
  controller.fetchOptions = async (value) => {
    payload = value;
    return { items: [] };
  };

  await controller.fetchAllRecords("alpha", new AbortController().signal);

  assert.deepEqual(payload, {
    kinds: controller.kindsValue,
    q: "alpha",
  });
});

test("times out an unresponsive record search", async () => {
  const controller = buildController({ requestTimeoutValue: 5 });
  globalThis.fetch = async (_url, { signal }) =>
    new Promise((_resolve, reject) => {
      signal.addEventListener("abort", () => {
        const error = new Error("aborted");
        error.name = "AbortError";
        reject(error);
      });
    });

  const result = await Promise.race([
    controller.fetchRecords("user", "alpha", new AbortController().signal),
    new Promise((resolve) => setTimeout(() => resolve({ error: "test-timeout" }), 100)),
  ]);

  assert.deepEqual(result, { error: "error" });
});

test("shows only current authorized catalog entries in recent items", () => {
  const stored = [
    { id: "users", kind: "navigate", label: "Old users", url: "/admin/users" },
    { id: "billing", kind: "navigate", label: "Billing", url: "/admin/billing" },
  ];
  globalThis.sessionStorage = { getItem: () => JSON.stringify(stored) };
  const current = { id: "users", kind: "navigate", label: "Users", url: "/admin/users" };
  const controller = buildController({ navigateValue: [current] });

  assert.deepEqual(controller.recentItems(), [current]);
});

test("uses localized requirement labels in action help", () => {
  const controller = buildController({
    optionalValue: "optional-local",
    requiredValue: "required-local",
  });
  controller.render = () => {};

  controller.showActionHelp({
    id: "create-user",
    params: [
      { name: "email", required: true },
      { name: "role", required: false },
    ],
  });

  assert.deepEqual(
    controller.visibleItems.map((item) => item.label),
    ["email= (required-local)", "role= (optional-local)"]
  );
});

test("lets Tab reach dialog links and traps focus inside the dialog", () => {
  let activeElement;
  const query = {
    focus() {
      activeElement = query;
    },
  };
  const link = {
    focus() {
      activeElement = link;
    },
  };
  globalThis.document = {
    get activeElement() {
      return activeElement;
    },
  };
  const controller = buildController({
    dialogTarget: { querySelectorAll: () => [link] },
    open: true,
    queryTarget: query,
  });
  const event = {
    key: "Tab",
    preventDefaultCalled: false,
    preventDefault() {
      this.preventDefaultCalled = true;
    },
    shiftKey: false,
  };

  query.focus();
  controller.onDialogKeydown(event);
  assert.equal(activeElement, link);
  assert.equal(event.preventDefaultCalled, true);

  event.shiftKey = true;
  controller.onDialogKeydown(event);
  assert.equal(activeElement, query);
});

test("preserves URL fragments after create-action query parameters", () => {
  const controller = buildController();

  const url = controller.applyQueryParams(
    "/admin/users/new?source=palette#details",
    { params: [{ name: "email", query_key: "user[email]" }] },
    { email: "ada@example.com" }
  );

  assert.equal(url, "/admin/users/new?source=palette&user%5Bemail%5D=ada%40example.com#details");
});

test("refuses executable URLs and cross-origin mutations", () => {
  let assignedUrl = null;
  globalThis.window = {
    confirm: () => true,
    location: {
      assign(url) {
        assignedUrl = url;
      },
      href: "https://admin.example.test/users",
      origin: "https://admin.example.test",
    },
  };
  const controller = buildController();
  let submitted = false;
  controller.close = () => {};
  controller.render = () => {};
  controller.submitMethod = () => {
    submitted = true;
  };

  controller.navigateItem({ kind: "user", method: "get", url: "javascript:alert(1)" });
  assert.equal(assignedUrl, null);
  assert.equal(controller.status, "error");

  controller.navigateItem({
    confirm: "Delete?",
    kind: "action",
    method: "delete",
    url: "https://other.example.test/delete",
  });
  assert.equal(submitted, false);
});

test("announces asynchronous search states", () => {
  const announcer = { textContent: "" };
  const query = {
    attributes: {},
    removeAttribute(name) {
      delete this.attributes[name];
    },
    setAttribute(name, value) {
      this.attributes[name] = value;
    },
  };
  const controller = buildController({
    announcerTarget: announcer,
    errorValue: "Search failed",
    hasAnnouncerTarget: true,
    queryTarget: query,
    status: "error",
  });

  controller.announceStatus();

  assert.equal(announcer.textContent, "Search failed");
  assert.equal(query.attributes["aria-busy"], "false");
});
