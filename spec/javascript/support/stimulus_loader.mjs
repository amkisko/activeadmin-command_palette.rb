const controllerPath =
  "/app/assets/controllers/activeadmin_command_palette/command_palette_controller.js";

export async function resolve(specifier, context, nextResolve) {
  if (specifier === "@hotwired/stimulus") {
    return {
      shortCircuit: true,
      url: new URL("./stimulus_stub.mjs", import.meta.url).href,
    };
  }

  return nextResolve(specifier, context);
}

export async function load(url, context, nextLoad) {
  if (new URL(url).pathname.endsWith(controllerPath)) {
    const loaded = await nextLoad(url, { ...context, format: "module" });
    return { ...loaded, format: "module" };
  }

  return nextLoad(url, context);
}
