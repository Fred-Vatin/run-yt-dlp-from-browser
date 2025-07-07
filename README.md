Todo:

[Test protocol](ytdl:?test)

- [ ] wiki

# Run yt-dlp commands from browser

This project contains a userscript (`user script/ytdl.user.js`) that allows you to run yt-dlp directly from your browser using [Tampermonkey](https://www.tampermonkey.net/) or other extensions for userscripts.

To enable your operating system (currently Windows only, but pull requests are welcome) to interpret data sent by the userscript, download the [powershell directory](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/tree/main/powershell). More details will be provided in the wiki.

## Requirements

_See wiki if you don’t know how to install and apply the requirements._

- `yt-dlp` and `ffmpeg` commands must be accessible in your `PATH`
- your browser needs the extension [Tampermonkey](https://www.tampermonkey.net/) to be installed
- your Windows user account must be allowed to run powershell script `.ps1`
- [Powershell 7](https://github.com/PowerShell/PowerShell) (strongly recommend to use winget to install it)
- (optional) by default it uses [Windows Terminal](https://apps.microsoft.com/detail/9n0dx20hk701) to run the powershell script that runs the `yt-dlp` command

## Installation

### Script for browser

To install the userscript in [Tampermonkey](https://www.tampermonkey.net/), click below:

[![Install Userscript](https://img.shields.io/badge/Install_Userscript-yt--dlp-blue?style=for-the-badge)](https://raw.githubusercontent.com/Fred-Vatin/run-yt-dlp-from-browser/main/user%20script/ytdl.user.js)

1. _Ensure the Tampermonkey extension is installed in your browser._
2. _Click the link above._
3. _Tampermonkey will automatically detect the script and prompt you to install it. Click "Install" in the Tampermonkey window._

### Script for Windows

- [ ] todo

## Automatic Updates

The user script is configured to automatically check for updates. If a new version is available in this GitHub repository, Tampermonkey will update it unless you modified it.

---

# Proof on concept

Once you read the wiki to understand how it works, you understand how easy it is to use this concept to run any OS commands from a browser.

Just fork this repository and enjoy !
