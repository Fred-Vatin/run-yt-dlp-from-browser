<#*==========================================================================
* ℹ   User Configuration File (config.ps1)
  Place this file in the same directory as "yt-download.ps1".
  And rename it "config.ps1"
  Documentation: https://github.com/Fred-Vatin/run-yt-dlp-from-browser/wiki/How-to-setup-and-use%E2%80%AF%3F
===========================================================================#>

# Force the script to run in verbose mode.
# Useful for debug before opening an issue.
New-Variable -Name Verbose -Value $false -Option Constant

# ---------------------------------------------------------------------------
# 1. PATHS & DIRECTORIES
# ---------------------------------------------------------------------------

# Subfolder name created inside the default OS Downloads directory
New-Variable -Name DownloadFolderName -Value "yt-dlp" -Option Constant

# Custom parent download directory (uncomment to override OS default)
# Note: Files will be saved in "$DownloadsPath/$DownloadFolderName"
# New-Variable -Name DownloadsPath -Value "E:\Parent\for\Downloads" -Option Constant

# ---------------------------------------------------------------------------
# 2. MEDIA SETTINGS & QUALITY
# ---------------------------------------------------------------------------

# Default video format/quality (optimized for social media uploads like X/Twitter)
New-Variable -Name VideoQuality -Value "bestvideo*[vcodec^=avc1]+bestaudio[acodec^=mp4a]/bestvideo*+bestaudio/best"

# Default video container extension
New-Variable -Name VideoContainer -Value "mp4" -Option Constant

# URLs that should automatically trigger audio-only downloads
New-Variable -Name AutoAudio -Value @("https://music.youtube.com/watch?v=") -Option Constant

# ---------------------------------------------------------------------------
# 3. FILE NAMING TEMPLATES
# ---------------------------------------------------------------------------

# Naming template including the channel/uploader name
New-Variable -Name TemplateNameChannel -Value "%(uploader|)s%(uploader& - )s%(title).70s.%(ext)s" -Option Constant

# Naming template using only the video title
New-Variable -Name TemplateNameTitle -Value "%(title).70s.%(ext)s" -Option Constant

# Set to $true to use templateNameTitle, or $false to use templateNameChannel
New-Variable -Name UseTitle -Value $true -Option Constant

# ---------------------------------------------------------------------------
# 4. AUTHENTICATION (COOKIES)
# ---------------------------------------------------------------------------

# Enable browser cookies extraction (highly recommended to avoid blocks)
New-Variable -Name UseBrowserCookies -Value $true -Option Constant

# Browser and optional profile name for cookie extraction (e.g., "firefox", "chrome", "edge")
New-Variable -Name BrowserCookies -Value "firefox:xyz.Youtube" -Option Constant

# Path to a dedicated cookies.txt file (not recommended for security reasons) (not a constant)
New-Variable -Name myCookies -Value "D:/pathTo/cookies.txt"

# ---------------------------------------------------------------------------
# 5. EXTERNAL TOOLS
# ---------------------------------------------------------------------------

# Path to the YDL-UI graphical interface executable
New-Variable -Name UI_Path -Value "D:/Path/To/YDL-UI_Portable/YDL-UI.exe" -Option Constant

# JavaScript runtime used by recent yt-dlp versions to improve download speed
# Comment this line to let yt-dlp auto-detect or use the slower fallback.
# See: https://github.com/yt-dlp/yt-dlp/wiki/ejs
New-Variable -Name JsRuntime -Value "bun" -Option Constant

# ---------------------------------------------------------------------------
# 6. USER EXPERIENCE & INTERFACE
# ---------------------------------------------------------------------------

# Automatically open file explorer and select the file once downloaded
New-Variable -Name SelectDownloadedFile -Value $true -Option Constant

# Enable colored console output (set to $false if characters render poorly)
New-Variable -Name UseColorfulOutput -Value $true -Option Constant

# Play an audio alert upon download success or failure
New-Variable -Name PlaySound -Value $true -Option Constant
