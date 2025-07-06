// ==UserScript==
// @name         yt-dlp
// @namespace    fred.vatin.yt-dlp.us
// @version      1.0.4
// @description  Run local script to run yt-dlp commands
// @icon         https://www.google.com/s2/favicons?sz=64&domain=youtube.com
// @author       Fred Vatin
// @updateURL    https://raw.githubusercontent.com/Fred-Vatin/run-yt-dlp-from-browser/main/user%20script/ytdl.user.js
// @downloadURL  https://raw.githubusercontent.com/Fred-Vatin/run-yt-dlp-from-browser/main/user%20script/ytdl.user.js
// @noframes
// @match        *://*.youtube.com/*
// @match        *://*.x.com/*
// @match        *://*.instagram.com/*
// @match        *://*.reddit.com/*
// @match        *://*.twitch.tv/*
// @match        *://rutube.ru/*
// @match        *://*.canalplus.com/*
// @grant        GM_registerMenuCommand
// @grant        GM_notification
// @grant        GM_openInTab
// @grant        GM_addStyle
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_info
// @license MIT
// ==/UserScript==

(() => {
  "use strict";
  const PROTOCOL = "ytdl:"; // don’t change this
  const EXCLUDE_URL_MATCH = ["accounts.youtube.com"];
  const DOWNLOAD_DIR = ""; // if you want to force another download dir then the one set in the powershell script;

  let closeDelay;

  // Log the script version
  console.log(`Run ${GM_info.script.name} ${GM_info.script.version}`);

  // Try to determine if this script is run for the first time at every download action
  function CheckFirstTime() {
    const firstTime = GM_getValue("first-time", true);
    console.log("Is script run for the first time:", firstTime);

    if (firstTime === true) {
      GM_setValue("first-time", false);
      // It will let time to user to accept the protocol default handler
      closeDelay = 100000;
    } else {
      closeDelay = 1000;
    }
  }

  let URL = window.location.href;
  console.log("URL (at first loading): ", URL);

  /**==========================================================================
   * ℹ		DETECT URL CHANGE TO RE-RUN THE SCRIPT
  ===========================================================================*/

  // Function to run when URL change
  function onUrlChange() {
    const currentUrl = window.location.href;
    if (currentUrl !== URL) {
      console.log("URL changed : ", currentUrl);
      URL = currentUrl;

      createButton();
    }
  }

  // Listen popstate event (that can change URL) used by some sites or the browser
  window.addEventListener("popstate", onUrlChange);

  // Listen a youtube specific event that change the URL
  document.addEventListener("yt-navigate-finish", onUrlChange);

  // same for music.youtube
  document.addEventListener("yt-page-data-updated", onUrlChange);

  // Call these functions immediately on the initial page load
  onUrlChange();
  createButton();

  /**==========================================================================
  * ℹ		BUILD URL PROTOCOL ytdl:
  ===========================================================================*/
  function isUrlExcluded(url) {
    // Checks if the URL matches any of the elements in the excludeUrlMatch array
    return EXCLUDE_URL_MATCH.some((e) => url.includes(e));
  }

  // Function to open the URL ytdl:
  function openYtdlURL(type, quality = "") {
    CheckFirstTime();
    URL = window.location.href;
    console.log("URL: ", URL);

    if (isUrlExcluded(URL)) {
      const ERRMSG = `yt-dlp: url “${URL}” is excluded from processing because of "excludeUrlMatch".`;

      console.info(ERRMSG);

      GM_notification({
        text: ERRMSG,
        title: "URL EXCLUDED",
        silent: false,
        timeout: 6000,
        onclick: (event) => {
          // The userscript is still running, so don't open any url when clicked
          event.preventDefault();
          // Display an alert message instead
          console.info("User clicked the notification");
        },
      });

      return;
    }

    const ytdlURL = `${PROTOCOL}?type=${type}&quality=${quality}&dldir=${DOWNLOAD_DIR}&url=${URL}`;

    // Use GM_openInTab to open the URL
    // This should trigger the ytdl: protocol handler if installed properly on the OS
    const tab = GM_openInTab(ytdlURL, {
      active: false,
      insert: true,
      setParent: true,
      loadInBackground: true,
    });
    console.info(`Try to open URL : ${ytdlURL}`);

    // Auto close the opened tab after a delay
    setTimeout(() => {
      tab.close();
    }, closeDelay); // Adjut this variable (in milliseconds) where it is delcared if necessary

    GM_notification({
      text: `Type: ${type}\nQuality: ${quality}`,
      title: "YT-DLP",
      silent: false,
      timeout: 6000,
      onclick: (event) => {
        // The userscript is still running, so don't open any url when clicked
        event.preventDefault();
        // Display an alert message instead
        console.info("User clicked the notification");
      },
    });
  }

  /**==========================================================================
  * ℹ		TAMPERMONKEY MENU CREATION
  ===========================================================================*/

  // Register those commands in Tampermonkey menu
  GM_registerMenuCommand(
    "Download auto (recommanded)",
    () => openYtdlURL("auto"),
    {
      accessKey: "r",
      title:
        "Shortkey: R. Try to download the best video or audio (avc1+m4a) streams available.",
    },
  );

  GM_registerMenuCommand("Download audio", () => openYtdlURL("audio"), {
    accessKey: "a",
    title:
      "Shortkey: A. Try to download the best audio (m4a) streams available.",
  });

  GM_registerMenuCommand(
    "Download mp3",
    () => openYtdlURL("audio", "forceMp3"),
    {
      accessKey: "m",
      title: "Shortkey: M. Extract or convert to mp3",
    },
  );

  GM_registerMenuCommand("Download 1080p", () => openYtdlURL("video", "1080"), {
    title: "Download at 1080p max if possible",
  });

  GM_registerMenuCommand("Download with YDL-UI", () => openYtdlURL("showUI"), {
    accessKey: "u",
    title: "Shortkey: U. Download with YDL-UI.exe if installed",
  });

  GM_registerMenuCommand("List formats", () => openYtdlURL("test"), {
    accessKey: "f",
    title: "Shortkey: F. Show URL details in terminal.",
  });

  GM_registerMenuCommand(
    "Reset first time value",
    GM_setValue("first-time", true),
    {
      title: "The opened ytdl: tab will stay open longer",
    },
  );

  /**==========================================================================
  * ℹ		CREATE BUTTON on YouTube
  ===========================================================================*/
  function createButton() {
    let isButtonCreated = false; // Variable pour éviter les créations multiples
    let isYoutube = false;
    let isMusic = false;
    let functionCall = 1;
    const containerID = "ytdl-button";

    function createYtdlButton() {
      console.log("createYtdlButton() call:", functionCall++);

      if (URL.startsWith("https://www.youtube.com/watch?v=")) {
        isYoutube = true;
      }

      if (URL.startsWith("https://music.youtube.com/watch?v=")) {
        isMusic = true;
      }

      console.log(`isYouTube: ${isYoutube}, isMusic: ${isMusic}`);

      if (!isYoutube && !isMusic) {
        ytdlContainerObserver.disconnect();
        console.log(
          "Button cannot be created because URL doesn't match YouTube or YouTube Music or a video is not playing",
        );
        deleteButton(containerID);
        return;
      }

      // Définir les sélecteurs cibles
      const targetSelectors = [
        "#container > #end",
        "ytmusic-nav-bar > #right-content",
      ];

      // Trouver le premier élément cible existant
      let targetElement = null;
      for (const selector of targetSelectors) {
        targetElement = document.querySelector(selector);
        if (targetElement) break;
      }

      // Si aucun élément cible n'est trouvé, arrêter
      if (!targetElement) {
        console.log("No element in the page to insert the button");
        return;
      }

      // Vérifier si le bouton existe déjà
      if (isButtonCreated || document.querySelector(`#${containerID}`)) {
        console.log(`The button #${containerID} already exists`);
        ytdlContainerObserver.disconnect();
        return;
      }

      // Marquer le bouton comme créé
      isButtonCreated = true;
      ytdlContainerObserver.disconnect();

      // Créer le conteneur du bouton
      const buttonContainer = document.createElement("div");
      buttonContainer.id = containerID;

      // Créer le bouton yt-icon-button sans enfants
      const iconButton = document.createElement("yt-icon-button");
      iconButton.id = "button";
      iconButton.setAttribute("style", "width: 40px; height: 40px");

      // Créer le tooltip sans enfants
      const tooltip = document.createElement("tp-yt-paper-tooltip");
      // tooltip.setAttribute("role", "tooltip");
      // tooltip.setAttribute("tabindex", "-1");
      // tooltip.setAttribute("aria-label", "Download with yt-dlp");
      tooltip.setAttribute("style", "left: -33.6667px; top: 54px");

      // Ajouter les éléments au conteneur
      buttonContainer.appendChild(iconButton);
      buttonContainer.appendChild(tooltip);

      // Ajouter l'événement click
      buttonContainer.addEventListener("click", () => {
        console.log('Button clicked, calling openYtdlURL("auto")');
        openYtdlURL("auto");
      });

      // Insérer le conteneur comme premier enfant de l'élément cible
      targetElement.insertBefore(buttonContainer, targetElement.firstChild);

      console.log(
        `Button container #${containerID} inserted into DOM, starting observing children while disconnecting ytdlContainerObserver`,
      );

      // Configurer les observateurs pour surveiller les enfants ajoutés
      setupDlButtonObservers(buttonContainer);

      GM_addStyle(`
      #${containerID} {
        position: relative;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-right: 8px;
        color: var(--paper-listbox-color, var(--primary-text-color));
      }
    `);
    }

    function deleteButton(id) {
      const button = document.getElementById(id);
      if (button) {
        button.remove(); // Removes the element from the DOM
        console.log("button detected and removed");
      } else {
        console.log("Tried to delete the button but it seems it doesn’t exist");
      }
    }

    function setupDlButtonObservers(buttonContainer) {
      const iconButton = buttonContainer.querySelector("yt-icon-button");
      const tooltipElement = buttonContainer.querySelector(
        "tp-yt-paper-tooltip",
      );

      // Observer pour yt-icon-button
      const iconButtonObserver = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.type === "childList") {
            const button = iconButton.querySelector("button");
            if (button && button.children.length === 0) {
              // Ajouter SVG au button
              const svg = document.createElementNS(
                "http://www.w3.org/2000/svg",
                "svg",
              );
              svg.setAttribute("viewBox", "0 0 24 24");
              svg.setAttribute("style", "width: 32px; height: 32px");

              const path1 = document.createElementNS(
                "http://www.w3.org/2000/svg",
                "path",
              );
              path1.setAttribute("d", "M19 15v4H5v-4H3v6h18v-6h-2z");
              path1.setAttribute("fill", "#ff0033");

              const path2 = document.createElementNS(
                "http://www.w3.org/2000/svg",
                "path",
              );
              path2.setAttribute("d", "M12 14l-7-7h14l-7 7z");
              path2.setAttribute("fill", "#ffffff");

              svg.appendChild(path1);
              svg.appendChild(path2);

              button.appendChild(svg);

              // Déconnecter l'observer
              iconButtonObserver.disconnect();
              console.log("Icon button modified and observer disconnected");
            }
          }
        });
      });

      iconButtonObserver.observe(iconButton, {
        childList: true,
        subtree: true,
      });

      // Observer pour tp-yt-paper-tooltip
      const tooltipObserver = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.type === "childList") {
            const tooltipDiv = tooltipElement.querySelector("#tooltip");
            if (tooltipDiv && tooltipDiv.textContent.trim() === "") {
              tooltipDiv.textContent = "Download with yt-dlp";
              // Déconnecter l'observer
              tooltipObserver.disconnect();
              console.log(
                "Tooltip modified and observer disconnected. Adding mouseenter/leave event",
              );

              // Ajouter les événements directement ici
              const button = document.querySelector(`#${containerID}`);
              const tooltipContainer = document.querySelector(
                `#${containerID} tp-yt-paper-tooltip`,
              );

              // needed to remove built-in listener that breaks the tooltip
              const clone = tooltipDiv.cloneNode(true);
              tooltipDiv.parentNode.replaceChild(clone, tooltipDiv);
              clone.setAttribute("style", "width: max-content;");

              // const tooltip = document.querySelector(`#${containerID} #tooltip`);

              console.log(`${containerID}`, button);
              console.log(`tooltipContainer`, tooltipContainer);
              console.log(`tooltip`, clone);

              function ytdlToggleTooltip(isHovering) {
                if (clone) {
                  if (isHovering) {
                    clone.classList.remove("hidden");
                    clone.classList.add("fade-in-animation");
                  } else {
                    clone.classList.remove("fade-in-animation");
                    clone.classList.add("hidden");
                  }
                }
              }

              if (clone && button) {
                button.addEventListener("mouseenter", () =>
                  ytdlToggleTooltip(true),
                );
                // tooltipContainer.addEventListener("mouseenter", () =>
                //   ytdlToggleTooltip(true),
                // );
                button.addEventListener("mouseleave", () =>
                  ytdlToggleTooltip(false),
                );
              }
            }
          }
        });
      });

      tooltipObserver.observe(tooltipElement, {
        childList: true,
        subtree: true,
      });
    }

    // Exécuter la fonction au chargement de la page
    // window.addEventListener("load", createYtdlButton);

    // Observer les changements dynamiques dans le DOM
    const ytdlContainerObserver = new MutationObserver(() => {
      console.log("Global mutation detected, running createYtdlButton()");
      createYtdlButton();
    });

    ytdlContainerObserver.observe(document.body, {
      childList: true,
      subtree: true,
    });
  }
})();
