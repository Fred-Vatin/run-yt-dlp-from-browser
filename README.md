# Run yt-dlp commands from browser

**This PC tool will allow you to download any video or music from your browser in one click using yt-dlp.**

This project contains a userscript (`user script/ytdl.user.js`) that allows you to run yt-dlp directly from your browser using [Tampermonkey](https://www.tampermonkey.net/) or other extensions for userscripts.

Check the [wiki](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/wiki) to learn how to install and use it.

## Screenshots

One click button on youtube

<img alt="image" src="https://github.com/user-attachments/assets/905a403c-ecbc-4521-bafb-ea58c22710b7" />

Menu for other formats and sites

<img alt="image" src="https://github.com/user-attachments/assets/bed1fa17-9624-4fe1-9321-4745063a38ce" />

Detailed output of the download job

<img alt="image" src="https://github.com/user-attachments/assets/1c204747-c193-4620-9df7-8147eb1d21c7" />


## Prerequisites

_See [wiki](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/wiki) to know how to install and apply the prerequisites._

- `yt-dlp` and `ffmpeg` commands must be accessible in your `PATH`
- your browser needs the extension [Tampermonkey](https://www.tampermonkey.net/) to be installed
- your Windows user account must be allowed to run powershell script `.ps1`
- [Powershell 7](https://github.com/PowerShell/PowerShell)

## Automatic Updates

The user script is configured to automatically check for updates. If a new version is available in this GitHub repository, Tampermonkey will update it unless you modified it.

But the powershell script won’t auto update. So watch the release to know when there is a new version with fixes or new features.

<img width="463" height="470" alt="image" src="https://github.com/user-attachments/assets/227caa77-15b7-4560-b804-d9930fa4559f" />
<img width="616" height="452" alt="image" src="https://github.com/user-attachments/assets/a0f43c4b-25ae-4aad-8fe2-a5a0531b6934" />

---

# Proof on concept

Once you read the wiki to understand how it works, you understand how easy it is to use this concept to run any OS commands from a browser.

Just [fork this repository](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/wiki/Make-your-own-command-handler) and enjoy !

# Trouble shooting

Just for debug purpose, there is a userscript to test the protocol handler in your browser.

To install the test protocol userscript in [Tampermonkey](https://www.tampermonkey.net/), click below:

[![Install Userscript](https://img.shields.io/badge/Install_Userscript-test-blue?style=for-the-badge)](https://raw.githubusercontent.com/Fred-Vatin/run-yt-dlp-from-browser/main/user%20script/test-protocol.user.js)

Read [how to reach help](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/wiki/Trouble-shooting).

---

[![BUY ME A COFFEE](https://img.shields.io/badge/BUY%20ME%20A%20COFFEE-ffffff?logo=buymeacoffee&style=for-the-badge&color=710067&logoColor=ffe071)](https://github.com/sponsors/Fred-Vatin)
