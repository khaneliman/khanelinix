import { app } from "../../scripts/app.js";

app.registerExtension({
	name: "khanelinix.local-first",
	setup() {
		const style = document.createElement("style");
		style.textContent = `
      .apps-tab-button,
      .model-library-tab-button,
      .templates-tab-button {
        display: none !important;
      }
    `;
		document.head.appendChild(style);
	},
});
