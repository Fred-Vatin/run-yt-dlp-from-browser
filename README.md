# Run yt-dlp commands from browser

This project contains a userscript (`user script/ytdl.user.js`) that allows you to run yt-dlp directly from your browser using [Tampermonkey](https://www.tampermonkey.net/) or other extensions for userscripts.

For your OS (only Windows currently but PR are welcome) interprets what the userscript sends, you need to download the [powershell directory](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/tree/main/powershell). Details in the wiki later.

## Requirements

_See wiki if you don’t know how to install and apply the requirements._

- `yt-dlp` and `ffmpeg` commands must be accessible in your `PATH`
- your browser needs the extension [Tampermonkey](https://www.tampermonkey.net/) to be installed
- your Windows user account must be allowed to run powershell script `.ps1`

## Installation

To install the userscript in [Tampermonkey](https://www.tampermonkey.net/), click below:

[![Install Userscript](https://img.shields.io/badge/Install_Userscript-yt--dlp-blue?style=for-the-badge)](https://raw.githubusercontent.com/Fred-Vatin/run-yt-dlp-from-browser/main/user%20script/ytdl.user.js)

_1. Ensure the Tampermonkey extension is installed in your browser._
_2. Click the link above._
_3. Tampermonkey will automatically detect the script and prompt you to install it. Click "Install" in the Tampermonkey window._

## Automatic Updates

The user script is configured to automatically check for updates. If a new version is available in this GitHub repository, Tampermonkey will update it unless you modified it.
