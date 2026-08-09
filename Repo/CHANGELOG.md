# Changelog

## [2.6.0](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v2.5.1...v2.6.0) (2026-08-09)


### 🚀 Features

* add debug output for defined variables in config.ps1 ([a467f86](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/a467f8659c60fcbd9c3a3055299651888f452577))
* implement Get-OSDownloadPath function for dynamic download directory resolution ([7d7e86d](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/7d7e86d1ecb9a704c93f3fa232c3b8adb701bd29))


### 🐞 Bug Fixes

* VideoQuality must not be a constant ([5510be8](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/5510be8ca3f387ad35209ae823317bbf5cc07b69))


### ✨ Polish

* rename error handling function from TerminateWithError to Stop-ScriptWithError ([1ec5a96](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/1ec5a96c9cd6a96ee127f971b02d77ecbfc25a33))
* standardize parameter casing and enhance verbose output in yt-download.ps1 ([ccd2612](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/ccd26126d4cffe4c0de774a609699702a9b7250d))
* standardize parameter casing and enhance verbose output in yt-download.ps1 ([72839db](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/72839db31a839cbcf270e59fbf08067e79c338b9))

## [2.5.1](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v2.5.0...v2.5.1) (2026-06-04)


### 🐞 Bug Fixes

* better error handling ([1d7b1f3](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/1d7b1f399e5c2b1e771a83189b1b5613a6d16148))
* enhance error handling with detailed messages and stack trace ([8ff1163](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/8ff11639ed4aef9330b24b38c3bfa01adcd8d0eb))
* update URL protocol handling in command generation ([22ef999](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/22ef999eabe990948c743c7915c772c16f7a0c46))

## [2.5.0](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v2.4.0...v2.5.0) (2026-06-03)


### 🚀 Features

* add colorful output option and enhance logging for download progress ([692b896](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/692b896b42f23d29aae26e402e9d09b73d542be0))
* add sound notifications for success and error events ([45635b6](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/45635b699654cd308f780ec1f59f8d8cd7abc38e))
* enhance metadata handling by adding support for title replacement in options ([1507011](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/15070118a3ca4947610cc658da0aabfbbf1c0d6e))
* enhance metadata handling by replacing invalid characters in video titles ([294d6e7](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/294d6e772e958a86745302e8839e25aba9f8808e))
* enhance UTF-8 encoding support in output ([10201af](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/10201af46476178183a42d23fb36ca6a0cdcc09a))
* improve download path handling and error reporting in yt-download.ps1 ([cf190ca](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/cf190ca9f2026d20353550f9149080469d04b47d))
* smartly open and select downloaded files in any file manager (Windows only) ([c8eb2d6](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/c8eb2d69df3b1b78f0b9c014fa61f9310fc67720))


### 🐞 Bug Fixes

* move myCookies variable initialization to maintain scope and improve cookie handling logic ([a176a48](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/a176a484030a507fc5aa800a85793229c8c32fd0)), closes [#18](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/issues/18)
* prevent -install or -uninstall on platforms other than Windows ([5f89c48](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/5f89c4808c07c3a63771497f295ddfc5f7ed4b23))
* TerminateWithError was called too late and user config was check too late also ([d8c6afa](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/d8c6afa742d01617e7e5280b7b796fb9f57814c2)), closes [#21](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/issues/21)


### ✨ Polish

* replace $global with $script to avoid global session pollution ([bdd4cf7](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/bdd4cf77d053a636fca24829c057b4d7ea864c25))

## [2.4.0](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v2.3.0...v2.4.0) (2026-05-31)


### 🚀 Features

* release 2.4.0 ([f73445d](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/f73445dd4bce68ebab5acb5baa9e37fce3eacd43))

## [2.3.0](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v2.2.0...v2.3.0) (2026-05-08)


### 🧰 Other

* add PowerShell config file to .gitignore ([9ceca70](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/9ceca70a8961124f791018d10a90e32b034d0b50))


### 🚀 Features

* **ps1:** use external config.ps1 ([1f0ba56](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/1f0ba566e17dc8d83af3df11f4ab1c7aa35a6370))

## [2.2.0](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v2.1.2...v2.2.0) (2026-05-06)


### 🚀 Features

* **js:** button now display a menu ([fe55dc6](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/fe55dc61e2e1151ef6d626d469ecf2ef4ac092c0))
* **ps1:** use cookies from browser ([621a651](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/621a651c391065262dbad1697457c98ec914d076))

## [2.1.2](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v2.1.1...v2.1.2) (2026-03-15)


### 🐞 Bug Fixes

* audio was not always downloaded with video ([f04444c](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/f04444c46af80aa66249ed4c5520f84c50139d4b))

## [2.1.1](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v2.1.0...v2.1.1) (2026-03-12)


### 🐞 Bug Fixes

* ERROR: [youtube] Requested format is not available. ([6467290](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/64672900252564973ee2aebc09bf3fd928cf3bda))

## [2.1.0](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v2.0.1...v2.1.0) (2026-01-02)


### 🚀 Features

* add send command to clipboard ([b9a586a](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/b9a586a6173c2b21855832a9e63a3b055f18763b))

## [2.0.1](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v2.0.0...v2.0.1) (2025-12-16)


### 🐞 Bug Fixes

* fallback to best to avoid failure ([9f7f6ff](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/9f7f6ff87dcdf86df541e2cbc51d0c8fe583a3f0)), closes [#9](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/issues/9)

## [2.0.0](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v1.2.0...v2.0.0) (2025-11-12)


### ⚠ BREAKING CHANGES

* release

### 🧰 Other

* release ([2aaf736](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/2aaf736216841acc5ffb0c098811e5270843c4fe))


### 🚀 Features

* add --js-runtimes support for yt-dlp 2025.11.12 ([70b24f5](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/70b24f5842773989de8cb2c38d7fe2ee2a01b9e3))
* add auto-detect user downloads folder ([43178a3](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/43178a37178124b0f42bc4c73576f72541ef04d4))
* add the "best" quality option to yt-dlp ([13decd0](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/13decd0fc3e721c0c78ce9d92f79fd60bf067394))
* cookie path ([ef8545f](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/ef8545f02f3dab981ff31ff6b757cb2c991d4d19))
* ps1 script allowed to be called manually with a simple url ([0b777b5](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/0b777b56905f661eccc452b2f0a9f387e5f58026))
* script active on all sites ([7e5927e](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/7e5927e56071fe7b5a56f391026b5a40de926633))
* use window.onurlchange event ([8f3aecc](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/8f3aecc6f0e15254dcaeccf762f7a1c513b6817a))
* **userscript:** add check first time logic ([0a7e0b2](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/0a7e0b28d4ba275590eae2a6e3127858438ab558))


### 🐞 Bug Fixes

* check ffmpeg installation ([4e77466](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/4e77466e59234212085acb73e3a8d5861760e560))
* open protocol in chromium ([edca49a](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/edca49a5dffd5e96c407c328e7109b83792c21b3))
* protocol changed to stop using Windows Terminal ([fa31fd1](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/fa31fd153fbd40ce949dda2a8fd9a25522343b2c))
* **ps1:** be sure output path is in quote ([6b8b9a9](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/6b8b9a9e50d3f78e2e1d37a07dba24fb9bdde875))
* **ps1:** quality variable and help ([ca49add](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/ca49addda006efc77e9000abb9e847f6fb60964c))
* userscript, bump version ([0abd231](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/0abd231f1e68d4f0b058b8a9092fbe4486379775))
* **userscript:** quality parameter was not prefixed with & ([06514e1](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/06514e1b2b95c94d04e2965b3f6e1f1f87a33f75))


### 🧪 Tests

* add window.onurlchange ([dbdba81](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/dbdba81791e8165f801c601d62d63b14ea814464))

## [1.2.0](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v1.1.0...v1.2.0) (2025-10-10)


### 🚀 Features

* ps1 script allowed to be called manually with a simple url ([0b777b5](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/0b777b56905f661eccc452b2f0a9f387e5f58026))

## [1.1.0](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v1.0.1...v1.1.0) (2025-10-10)


### 🚀 Features

* script active on all sites ([7e5927e](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/7e5927e56071fe7b5a56f391026b5a40de926633))

## [1.0.1](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v1.0.0...v1.0.1) (2025-10-09)


### 🐞 Bug Fixes

* check ffmpeg installation ([4e77466](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/4e77466e59234212085acb73e3a8d5861760e560))

## [1.0.0](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/compare/v0.1.0...v1.0.0) (2025-09-22)


### ⚠ BREAKING CHANGES

* release

### 🧰 Other

* release ([2aaf736](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/2aaf736216841acc5ffb0c098811e5270843c4fe))


### 🚀 Features

* add auto-detect user downloads folder ([43178a3](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/43178a37178124b0f42bc4c73576f72541ef04d4))
* add the "best" quality option to yt-dlp ([13decd0](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/13decd0fc3e721c0c78ce9d92f79fd60bf067394))
* cookie path ([ef8545f](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/ef8545f02f3dab981ff31ff6b757cb2c991d4d19))
* use window.onurlchange event ([8f3aecc](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/8f3aecc6f0e15254dcaeccf762f7a1c513b6817a))
* **userscript:** add check first time logic ([0a7e0b2](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/0a7e0b28d4ba275590eae2a6e3127858438ab558))


### 🐞 Bug Fixes

* open protocol in chromium ([edca49a](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/edca49a5dffd5e96c407c328e7109b83792c21b3))
* protocol changed to stop using Windows Terminal ([fa31fd1](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/fa31fd153fbd40ce949dda2a8fd9a25522343b2c))
* **ps1:** be sure output path is in quote ([6b8b9a9](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/6b8b9a9e50d3f78e2e1d37a07dba24fb9bdde875))
* **ps1:** quality variable and help ([ca49add](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/ca49addda006efc77e9000abb9e847f6fb60964c))
* userscript, bump version ([0abd231](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/0abd231f1e68d4f0b058b8a9092fbe4486379775))
* **userscript:** quality parameter was not prefixed with & ([06514e1](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/06514e1b2b95c94d04e2965b3f6e1f1f87a33f75))


### 🧪 Tests

* add window.onurlchange ([dbdba81](https://github.com/Fred-Vatin/run-yt-dlp-from-browser/commit/dbdba81791e8165f801c601d62d63b14ea814464))
