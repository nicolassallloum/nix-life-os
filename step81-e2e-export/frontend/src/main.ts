import "./assets/main.css";

import { createApp } from "vue";
import type { ComponentPublicInstance } from "vue";
import App from "./App.vue";
import router from "./router";
import { getApiErrorMessage } from "./services/api";

const app = createApp(App);

function getComponentName(instance: ComponentPublicInstance | null): string {
  const internalInstance = instance as unknown as {
    type?: {
      name?: string;
      __name?: string;
    };
  } | null;

  return internalInstance?.type?.name || internalInstance?.type?.__name || "UnknownComponent";
}

app.config.errorHandler = (error, instance, info) => {
  console.error("Vue global error:", {
    message: getApiErrorMessage(error, "Unexpected frontend error."),
    info,
    component: getComponentName(instance),
    error,
  });
};

window.addEventListener("unhandledrejection", (event: PromiseRejectionEvent) => {
  console.error("Unhandled promise rejection:", getApiErrorMessage(event.reason));
});

app.use(router).mount("#app");
