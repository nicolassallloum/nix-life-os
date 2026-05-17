import "./assets/main.css";

import { createApp } from "vue";
import App from "./App.vue";
import router from "./router";
import { getApiErrorMessage } from "./services/api";

const app = createApp(App);

app.config.errorHandler = (error, instance, info) => {
  console.error("Vue global error:", {
    message: getApiErrorMessage(error, "Unexpected frontend error."),
    info,
    component: instance?.type?.name || instance?.type?.__name || "UnknownComponent",
    error,
  });
};

window.addEventListener("unhandledrejection", (event) => {
  console.error("Unhandled promise rejection:", getApiErrorMessage(event.reason));
});

app.use(router).mount("#app");
