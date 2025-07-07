// ==UserScript==
// @name         GitHub YTDL Test Protocol Link
// @namespace    fred.vatin.yt-dlp-test.us
// @version      1.0.8
// @description  Adds a "Test Protocol" button in the source GitHub repository page
// @author       Fred Vatin
// @icon         https://www.google.com/s2/favicons?sz=64&domain=github.com
// @updateURL    https://raw.githubusercontent.com/Fred-Vatin/run-yt-dlp-from-browser/main/user%20script/test-protocol.user.js
// @downloadURL  https://raw.githubusercontent.com/Fred-Vatin/run-yt-dlp-from-browser/main/user%20script/test-protocol.user.js
// @match        https://github.com/Fred-Vatin/run-yt-dlp-from-browser
// @noframes
// @grant        none
// ==/UserScript==

(() => {
	"use strict";

	console.log(`Run ${GM_info.script.name} ${GM_info.script.version}`);

	const elID = "ytdl-test-link-container";
	const delay = 2000;

	function addYTDLLink() {
		const targetElement = document.querySelector(
			'nav[aria-label="Repository files"]',
		);

		if (targetElement) {
			// Vérifie si le conteneur du lien existe déjà pour éviter les duplications
			if (document.getElementById(elID)) {
				console.log(`${elID} already exists, skipping addition.`);
				return;
			}

			// Crée un nouvel élément a
			const linkContainer = document.createElement("a");
			linkContainer.id = elID;
			linkContainer.classList.add("btn", "d-none", "d-md-block", "ml-0");
			linkContainer.textContent = "Testez le protocole YTDL";
			linkContainer.setAttribute("target", "_blank");
			linkContainer.textContent = "Test YTDL protocol";
			linkContainer.href = "ytdl:?test";
			linkContainer.style.marginRight = "15px";

			targetElement.parentNode.insertBefore(
				linkContainer,
				targetElement.nextSibling,
			);
			console.log("Button added successfully.");
		}
	}

	setTimeout(() => {
		// --- Actions à effectuer après 3 secondes ---
		console.log(`${delay / 1000} secondes se sont écoulées !`);

		const observer = new MutationObserver((mutationsList, observer) => {
			// Exécute addYTDLLink seulement si le conteneur n'existe pas déjà
			if (!document.getElementById(elID)) {
				console.log("Mutation detected: Attempting to add button.");
				addYTDLLink();
				observer.disconnect();
			} else {
				// Une fois que le bouton est ajouté, on peut déconnecter l'observateur pour économiser des ressources
				// Il se peut que l'observateur détecte des mutations avant le premier appel de addYTDLLink
				// c'est pourquoi nous appelons aussi addYTDLLink une fois au début.
				console.log(
					"Mutation detected: Button already present, observer disconnected.",
				);
				observer.disconnect();
			}
		});

		observer.observe(document.body, { childList: true, subtree: true });

		// Exécute une première fois au cas où la page est déjà chargée (évite le délai de l'observateur)
		addYTDLLink();
	}, delay);
})();
