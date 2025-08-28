// ==UserScript==
// @name         yt-dlp
// @namespace    fred.vatin.yt-dlp.us
// @version      1.0.29
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
// @grant        GM_unregisterMenuCommand
// @grant        GM_notification
// @grant        GM_addStyle
// @grant        GM_info
// @grant        window.onurlchange
// @license MIT
// ==/UserScript==

(() => {
  "use strict";
  const PROTOCOL = "ytdl:"; // don’t change this
  const EXCLUDE_URL_MATCH = ["accounts.youtube.com"];
  const DOWNLOAD_DIR = ""; // if you want to force another download dir then the one set in the powershell script;

  // Log the script version
  console.log(`Run ${GM_info.script.name} ${GM_info.script.version}`);

  // Try to determine if this script is run for the first time at every download action

  const URL_ORIGIN = window.location.href; // could be useful if adding more sites support later
  let URL = window.location.href;
  console.log("URL (at first loading): ", URL);

  /**==========================================================================
   * ℹ		DETECT URL CHANGE TO RE-RUN THE SCRIPT
  ===========================================================================*/
  if (window.onurlchange === null) {
    console.log("window.onurlchange is supported. Adding 'urlchange' listener.");

    window.addEventListener("urlchange", () => {
      onUrlChange("window.onurlchange");
    });
  } else {
    console.log("window.onurlchange is not supported by this browser this Tampermonkey version.");
  }

  // Function to run when URL change
  function onUrlChange(event = "first loading") {
    const currentUrl = window.location.href;
    console.log(`onUrlChange call by event: ${event}`);

    if (currentUrl !== URL) {
      console.log("URL changed : ", currentUrl);
      URL = currentUrl;

      createButton();
    }
  }

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

    let ytdlURL = `${PROTOCOL}?type=${type}`;

    // Array to collect query parameters
    const params = [];
    if (quality) params.push(`quality=${quality}`);
    if (DOWNLOAD_DIR) params.push(`dldir=${DOWNLOAD_DIR}`);

    // Join parameters with '&' and append to URL
    ytdlURL += params.join("&");
    ytdlURL += `&url=${URL}`;

    // This should trigger the ytdl: protocol handler if installed properly on the OS
    window.location.href = ytdlURL;
    console.info(`Try to open URL : ${ytdlURL}`);

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
  GM_registerMenuCommand("Download auto (recommanded)", () => openYtdlURL("auto"), {
    accessKey: "r",
    title: "Shortkey: R. Try to download the best video or audio (avc1+m4a) streams available.",
  });

  GM_registerMenuCommand("Download audio", () => openYtdlURL("audio"), {
    accessKey: "a",
    title: "Shortkey: A. Try to download the best audio (m4a) streams available.",
  });

  GM_registerMenuCommand("Download mp3", () => openYtdlURL("audio", "forceMp3"), {
    accessKey: "m",
    title: "Shortkey: M. Extract or convert to mp3",
  });

  GM_registerMenuCommand("Download 1080p", () => openYtdlURL("video", "1080"), {
    title: "Download at 1080p max if possible",
  });

  GM_registerMenuCommand("Download Best Video", () => openYtdlURL("video", "best"), {
    title: "Download the best streams it founds",
  });

  GM_registerMenuCommand("Download with YDL-UI", () => openYtdlURL("showUI"), {
    accessKey: "u",
    title: "Shortkey: U. Download with YDL-UI.exe if installed",
  });

  GM_registerMenuCommand("List formats", () => openYtdlURL("test"), {
    accessKey: "f",
    title: "Shortkey: F. Show URL details in terminal.",
  });

  /**==========================================================================
  * ℹ		CREATE BUTTON on YouTube
  ===========================================================================*/
  function createButton(del = false) {
    let isButtonCreated = false; // to avoid multicreation
    let isYoutube = false;
    let isMusic = false;
    let functionCall = 1;
    const containerID = "ytdl-button";

    const ytdlContainerObserver = new MutationObserver(() => {
      if (!del) {
        console.log("Global mutation detected, running createYtdlButton()");
        createYtdlButton();
      } else {
        console.log("Global mutation detected, running deleteButton()");
        deleteButton(containerID);
      }
    });

    ytdlContainerObserver.observe(document.body, {
      childList: true,
      subtree: true,
    });

    function createYtdlButton() {
      console.log("createYtdlButton() call:", functionCall++);

      // update url
      URL = window.location.href;

      if (URL.startsWith("https://www.youtube.com/watch?v=")) {
        isYoutube = true;
      }

      if (URL.startsWith("https://music.youtube.com/watch?v=")) {
        isMusic = true;
      }

      console.log(`with url: ${URL}`);
      console.log(`isYouTube: ${isYoutube}, isMusic: ${isMusic}`);

      if (!isYoutube && !isMusic) {
        console.log(
          "Button cannot be created because URL doesn't match YouTube or YouTube Music or a video is not playing",
        );
        deleteButton(containerID);
        return;
      }

      const targetSelectors = ["#container > #end", "ytmusic-nav-bar > #right-content"];

      // Find first target element
      let targetElement = null;
      for (const selector of targetSelectors) {
        targetElement = document.querySelector(selector);
        if (targetElement) break;
      }

      // If none target element is found, stop
      if (!targetElement) {
        console.log("No element in the page to insert the button");
        return;
      }

      // Check if button already exists
      if (isButtonCreated || document.querySelector(`#${containerID}`)) {
        console.log(`The button #${containerID} already exists`);
        ytdlContainerObserver.disconnect();
        return;
      }

      // Mark button as created
      isButtonCreated = true;
      ytdlContainerObserver.disconnect();

      // Create button container
      const buttonContainer = document.createElement("div");
      buttonContainer.id = containerID;

      // Create yt-icon-button with no children
      const iconButton = document.createElement("yt-icon-button");
      iconButton.id = "button";
      iconButton.setAttribute("style", "width: 40px; height: 40px");

      // Create tooltip with no children
      const tooltip = document.createElement("tp-yt-paper-tooltip");
      // tooltip.setAttribute("role", "tooltip");
      // tooltip.setAttribute("tabindex", "-1");
      // tooltip.setAttribute("aria-label", "Download with yt-dlp");
      tooltip.setAttribute("style", "left: -33.6667px; top: 54px");

      // Add elements to container
      buttonContainer.appendChild(iconButton);
      buttonContainer.appendChild(tooltip);

      // Add click event
      buttonContainer.addEventListener("click", () => {
        console.log('Button clicked, calling openYtdlURL("auto")');
        openYtdlURL("auto");
      });

      // Insert container as the first child of target element
      targetElement.insertBefore(buttonContainer, targetElement.firstChild);

      console.log(
        `Button container #${containerID} inserted into DOM, starting observing children while disconnecting ytdlContainerObserver`,
      );

      // Start observing if new children are added by youtube to container
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
        ytdlContainerObserver.disconnect();
      } else {
        console.log("Tried to delete the button but it seems it doesn’t exist");
        ytdlContainerObserver.disconnect();
      }
    }

    function setupDlButtonObservers(buttonContainer) {
      const iconButton = buttonContainer.querySelector("yt-icon-button");
      const tooltipElement = buttonContainer.querySelector("tp-yt-paper-tooltip");

      // Setup observer for yt-icon-button
      const iconButtonObserver = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.type === "childList") {
            const button = iconButton.querySelector("button");
            if (button && button.children.length === 0) {
              // Add SVG to button
              const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
              svg.setAttribute("viewBox", "0 0 24 24");
              svg.setAttribute("style", "width: 32px; height: 32px");

              const path1 = document.createElementNS("http://www.w3.org/2000/svg", "path");
              path1.setAttribute("d", "M19 15v4H5v-4H3v6h18v-6h-2z");
              path1.setAttribute("fill", "#ff0033");

              const path2 = document.createElementNS("http://www.w3.org/2000/svg", "path");
              path2.setAttribute("d", "M12 14l-7-7h14l-7 7z");
              path2.setAttribute("fill", "#ffffff");

              svg.appendChild(path1);
              svg.appendChild(path2);

              button.appendChild(svg);

              iconButtonObserver.disconnect();
              console.log("Icon button modified and observer disconnected");
            }
          }
        });
      });

      // start observer
      iconButtonObserver.observe(iconButton, {
        childList: true,
        subtree: true,
      });

      // Setup observer for tp-yt-paper-tooltip
      const tooltipObserver = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.type === "childList") {
            const tooltipDiv = tooltipElement.querySelector("#tooltip");
            if (tooltipDiv && tooltipDiv.textContent.trim() === "") {
              tooltipDiv.textContent = "Download with yt-dlp";

              tooltipObserver.disconnect();
              console.log("Tooltip modified and observer disconnected. Adding mouseenter/leave event");

              // Add events here
              const button = document.querySelector(`#${containerID}`);
              const tooltipContainer = document.querySelector(`#${containerID} tp-yt-paper-tooltip`);

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
                button.addEventListener("mouseenter", () => ytdlToggleTooltip(true));
                // tooltipContainer.addEventListener("mouseenter", () =>
                //   ytdlToggleTooltip(true),
                // );
                button.addEventListener("mouseleave", () => ytdlToggleTooltip(false));
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
  }
})();
