param(
  [switch]$install,
  [switch]$uninstall,
  [switch]$help,
  [switch]$man,
  [switch]$version,
  [string]$url,
  [switch]$debug
)

# Stop the script if an error occurs.
$ErrorActionPreference = 'Stop'

$ScriptVersion = "2.5.0"

<#*==========================================================================
*	ℹ		PARAMETERS

  Run the script with the -help parameter to know how to use it
===========================================================================#>

<#*==========================================================================
* ℹ                   DEFAULT VARIABLES
===========================================================================#>

# Don’t edit this part unless you know what you do.
# Get default downloads dir for each platform
if (-not $DownloadsPath) {
  if ($PSVersionTable.Platform -eq "Win32NT") {
    New-Variable -Name UserShellFolders -Value "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Option Constant
    New-Variable -Name downloadsKey -Value "{374DE290-123F-4565-9164-39C4925E467B}" -Option Constant
    New-Variable -Name DownloadsPath -Value ((Get-ItemProperty -Path $UserShellFolders -Name $downloadsKey).$downloadsKey) -Option Constant
  }
  elseif ($PSVersionTable.Platform -eq "Unix") {
    New-Variable -Name DownloadsPath -Value (Join-Path -Path $HOME -ChildPath "Downloads") -Option Constant
  }
  else {
    Write-Host "ERROR`n" -ForegroundColor Red
    Write-Host "`tUnknown OS :`n`tCan not get the default Download directory." -ForegroundColor Red
    Write-Host "`n`tOpen an issue. You can try to set the DownloadsPath in your `"config.ps1`" file.`nEXIT" -ForegroundColor Red
    exit 1
  }
}
else {
  # Check if the DownloadsPath set in config.ps1 exists
  if (-not (Test-Path -Path $DownloadsPath -PathType Container)) {
    Write-Host "ERROR`n" -ForegroundColor Red
    Write-Host "`t`"$DownloadsPath`" :`n`tdoesn’t exist." -ForegroundColor Red
    Write-Host "`n`tYou set a custom download path which is invalid in your `"config.ps1`" file.`nEXIT" -ForegroundColor Red
    Write-Host "`tProvide a valid path or" -ForegroundColor Red
    Write-Host "`ttry to comment the line to use default download dir for user.`nEXIT" -ForegroundColor Red
    exit 1
  }
}

#===========================================================================
# import user config
try {
  $ConfigPath = Join-Path $PSScriptRoot "config.ps1"
  if (Test-Path $ConfigPath) {
    . $ConfigPath
  }
  else {
    TerminateWithError -errorMessage "`"config.ps1`" is missing."
  }
}
catch {
  TerminateWithError -errorMessage "`"config.ps1`" is missing or can not be loaded."
}

$Defaults = @{
  autoAudio            = @("https://music.youtube.com/watch?v=")
  browserCookies       = "firefox"
  DownloadFolderName   = "yt-dlp"
  SelectDownloadedFile = $true
  templateNameChannel  = "%(uploader)s - %(title)s.%(ext)s"
  templateNameTitle    = "%(title)s.%(ext)s"
  UI_Path              = ""
  UseBrowserCookies    = $true
  UseColorfulOutput    = $true
  useTitle             = $true
  videoContainer       = "mp4"
  videoQuality         = "best"
}

foreach ($VarName in $Defaults.Keys) {
  if (-not (Get-Variable -Name $VarName -ErrorAction SilentlyContinue)) {
    # Required variable is missing in config.ps1, let’s create it here with the default value
    New-Variable -Name $VarName -Value $Defaults[$VarName] -Option Constant -Confirm:$false
    Write-Host
    Write-Warning "Variable '$VarName' is missing in your `"config.ps1`". We will use the fallback value: `"$($Defaults[$VarName])`""
    Write-Host
  }
}

$myCookies = ""
#===========================================================================

New-Variable -Name FullDownloadDir -Value (Join-Path -Path "$DownloadsPath" -ChildPath "$DownloadFolderName") -Option Constant

# This is the command triggered by the protocol
# It open the Windows Terminal with the profile 'PowerShell 7' and this script with the given url
New-Variable -Name command -Value "cmd.exe /c pwsh.exe -ExecutionPolicy Bypass -NoExit -File ""$PSCommandPath"" -url ""%1"""

# ⚠	NOT RECOMMENDED
# If for some reason, you would want to change the protocol name.
# But you will also have to change the userscript run by your browser.
New-Variable -Name protocol -Value "ytdl"

New-Variable -Name repo -Value "https://github.com/Fred-Vatin/run-yt-dlp-from-browser" -Option Constant

New-Variable -Name IsTest -Value $false

<#*==========================================================================
* ℹ                   FUNCTIONS
===========================================================================#>
function Show-Version {
  Write-Host ""
  Write-Host "yt-download" -ForegroundColor Yellow
  Write-Host "Version : " -NoNewline
  Write-Host "$ScriptVersion" -ForegroundColor Green
  Write-Host ""
}


# Display help message with specified formatting
function Show-Help {
  Show-Version
  Write-Host ""
  Write-Host "ℹ`tPARAMETERS" -ForegroundColor Magenta
  Write-Host "========================`n" -ForegroundColor Magenta
  Write-Host "-help" -ForegroundColor Magenta
  Write-Host "`tOpen this help (default)`n"
  Write-Host "-man" -ForegroundColor Magenta
  Write-Host "`tUse this to open wiki at `"$repo`"`n"
  Write-Host "-install" -ForegroundColor Magenta
  Write-Host "`tUse this to register the custom protocol `"$protocol`://`" in the registry that will run this script with the parameter -url when called`n"
  Write-Host "`tThe downloads directory will be `"$FullDownloadDir`" and must exist. Edit this script to customize.`n"
  Write-Host "-uninstall" -ForegroundColor Magenta
  Write-Host "`tUse this to unregister the custom protocol `"$protocol`://`" from the registry`n"
  Write-Host "-url" -ForegroundColor Magenta
  Write-Host "`tThis url is parsed and can contain those parameters:"
  Write-Host "`n`t- type [string] (required)" -ForegroundColor Cyan
  Write-Host "`t`t`"auto`"`n`t`t`tif the url to download is detected as audio, download best audio"
  Write-Host "`t`t`tif not, download the url using best compatible video+audio"
  Write-Host "`n`t`t`"audio`"`n`t`t`tdownload audio stream only or extract audio"
  Write-Host "`n`t`t`"video`"`n`t`t`tdownload video stream as mp4 using `"quality`""
  Write-Host "`n`t`t`"test`"`n`t`t`tdisplay all available formats for the url and its title"
  Write-Host "`n`t`t`"showUI`"`n`t`t`tif YDL-UI.exe is installed and path set in this script, send url to it"
  Write-Host "`t`t`tRequires https://github.com/Maxstupo/ydl-ui/"
  Write-Host "`n`tquality [string] (optional)" -ForegroundColor Cyan
  Write-Host "`t`t`"`"`n`t`t`tdefault is empty and download the best compatible audio and video, not always the best"
  Write-Host "`n`t`t`"best`"`n`t`t`tif type is video try to download the best streams available, no matter what their format are"
  Write-Host "`n`t`t`"1080`", `"720`", etc.`n`t`t`tuse any height you want. It will try to download this video quality if exist or the next one below"
  Write-Host "`n`t`t`"forceMp3`"`n`t`t`tif type is audio, download mp3 stream if exists or convert to mp3"
  Write-Host "`n`t`t`"best, aac, m4a, mp3, opus, vorbis, wav`"`n`t`t`tif type is audio, use the given quality in priority, else find the other best audio stream"
  Write-Host "`n`t- dldir [string] (optional)" -ForegroundColor Cyan
  Write-Host "`t`t`"directory/path`"`n`t`t`tif not set in the -url, use the one set in this script"
  Write-Host "`n`t- url [string] (required)" -ForegroundColor Cyan
  Write-Host "`t`t`"url`"`tto download"
  Write-Host "`nℹ`tDefault Paths" -ForegroundColor Magenta
  Write-Host "========================`n" -ForegroundColor Magenta
  Write-Host "Edit this script to customize those paths."
  Write-Host "`"/`" as separator works also in Windows.`n"
  Write-Host "FullDownloadDir" -ForegroundColor Magenta
  Write-Host "`t$FullDownloadDir`n"
  Write-Host "UI_Path" -ForegroundColor Magenta
  Write-Host "`t$UI_Path`n"
  Write-Host "UseBrowserCookies (ignore \"myCookies\" if true)" -ForegroundColor Magenta
  Write-Host "`t$UseBrowserCookies`n"
  Write-Host "browserCookies" -ForegroundColor Magenta
  Write-Host "`t$browserCookies`n"
  Write-Host "myCookies" -ForegroundColor Magenta
  Write-Host "`t$myCookies`n"
}

function TerminateWithError {
  param(
    [string]$errorMessage = "Error happened.`nEXIT",
    [System.Exception]$exception
  )

  [console]::beep(1000, 100)
  [console]::beep(1000, 100)
  [console]::beep(1000, 100)
  [console]::beep(1000, 1000)

  if ($exception) {
    $line = $_.InvocationInfo.ScriptLineNumber

    if ($line) {
      Write-Host "`n$errorMessage :`n`t$($exception.Message)`n`tLine: $line`nEXIT" -ForegroundColor Red
    }
    else {
      Write-Host "`n$errorMessage :`n$($exception.Message)`nEXIT" -ForegroundColor Red
    }
  }
  else {
    Write-Host "ERROR`n" -ForegroundColor Red
    Write-Host "   $errorMessage`n`nEXIT" -ForegroundColor Red
  }

  exit 1
}

function WriteTitle {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $false)]
    [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::Cyan
  )

  Write-Host "`n===== $Title =====`n" -ForegroundColor $ForegroundColor
}

# Check if the script is running with administrative privileges
function Test-AdminPrivileges {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]$identity
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-YtdlInstallation {
  if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    TerminateWithError -errorMessage "yt-dlp is not installed globally on the system. Install it or add it to the PATH. You may need to restart the browser from where you call the command"
  }
}

function Get-YtdlPath {

  # Check install path
  $ytdlPath = (Get-Command yt-dlp -ErrorAction SilentlyContinue).Source

  if (Test-Path -Path $ytdlPath) {
    Write-Host "`nYt-dlp path was found:"
    Write-Host "$ytdlPath" -ForegroundColor Cyan

    return $ytdlPath
  }
  else {
    Write-Host "Yt-dlp path was not found" -ForegroundColor Yellow
    return $false
  }

}

function Test-FFmpegInstallation {
  if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    TerminateWithError -errorMessage "FFmpeg is not installed globally on the system. Install it or add it to the PATH. You may need to restart the browser from where you call the command."
  }
}

# Colorize yt-dlp output
function Out-ColoredLog {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$InputObject
  )

  begin {
    $script:lastWasProgress = $false
  }

  process {
    if ($InputObject -match '^(\[(?<tag>.+?)\])(?<remainder>.*)$') {
      $tag = $Matches['tag']
      $remainder = $Matches['remainder']

      if ($tag -eq 'debug') {
        if ($script:lastWasProgress) { Write-Host "" }
        Write-Host $InputObject -ForegroundColor DarkGray
        $script:lastWasProgress = $false
      }
      elseif ($tag -eq 'info') {
        if ($script:lastWasProgress) { Write-Host "" }
        Write-Host $InputObject -ForegroundColor DarkCyan
        $script:lastWasProgress = $false
      }
      else {
        $color = switch ($tag) {
          'download' { 'Green' }
          'warning' { 'Yellow' }
          'error' { 'Red' }
          'youtube' { 'Cyan' }
          default { 'White' }
        }

        if ($tag -eq 'download') {
          # Identify standard progress lines (ex: 96.1% or 100.0%)
          $isProgress = $remainder -match '\d+\.\d+%' -and $remainder -notmatch '100%\s+of'

          if ($isProgress) {
            # Overwrite the current line using \r
            Write-Host "$([char]13)[$tag]" -ForegroundColor $color -NoNewline
            Write-Host "$remainder" -NoNewline
            $script:lastWasProgress = $true
          }
          else {
            # If this is the final '100% of' summary, we overwrite the last progress line
            # instead of adding a newline, fulfilling the update logic.
            if ($script:lastWasProgress -and $remainder -match '100%\s+of') {
              Write-Host "$([char]13)[$tag]" -ForegroundColor $color -NoNewline
              Write-Host $remainder
            }
            else {
              if ($script:lastWasProgress) { Write-Host "" }
              Write-Host "[$tag]" -ForegroundColor $color -NoNewline
              Write-Host $remainder
            }
            $script:lastWasProgress = $false
          }
        }
        else {
          if ($script:lastWasProgress) { Write-Host "" }
          Write-Host "[$tag]" -ForegroundColor $color -NoNewline
          Write-Host $remainder
          $script:lastWasProgress = $false
        }
      }
    }
    else {
      if (-not [string]::IsNullOrWhiteSpace($InputObject)) {
        if ($script:lastWasProgress) { Write-Host "" }
        Write-Host $InputObject
        $script:lastWasProgress = $false
      }
    }
  }

  end {
    if ($script:lastWasProgress) { Write-Host "" }
  }
}
<#*==========================================================================
* ℹ            GET PARAMETERS
===========================================================================#>
if ($version) {
  Show-Version
  Write-Host "Source  : " -NoNewline
  Write-Host "https://github.com/Fred-Vatin/run-yt-dlp-from-browser" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "Run with the " -NoNewline
  Write-Host "-help " -ForegroundColor Magenta -NoNewline
  Write-Host "parameter for more info"
  exit
}

<#*==========================================================================
* ℹ		HANDLE HELP PARAMETER
===========================================================================#>

if ((-not $install -and -not $uninstall -and -not $man -and -not $url) -or ($help)) {
  Show-Help
  exit
}

<#*==========================================================================
* ℹ		HANDLE MAN PARAMETER
===========================================================================#>
if ($man) {
  Start-Process "$repo"
  exit
}
<#*==========================================================================
* ℹ		HANDLE URL PARAMETER
===========================================================================#>
# Handle -url parameter if no other parameters are specified
if ($url -and -not $install -and -not $uninstall) {
  Show-Version

  Write-Host "`nScript called with argument " -NoNewline
  Write-Host "-url" -ForegroundColor Magenta
  Write-Host "`t$url`n"

  try {

    # If you call the script with -url only, create default command
    if ($url.StartsWith("https://")) {
      $url = "ytdl:?type=auto&url=$url"
    }

    # Extract parts after ytdl:?
    if ($url.StartsWith("${protocol}:?")) {
      $startIndex = $url.IndexOf("${protocol}:?") + "${protocol}:?".Length
      $queryString = $url.Substring($startIndex)
    }
    else {
      TerminateWithError -errorMessage "Expected URL must start with: \"${protocol}:?\"`n   However URL is: $url"
    }

    # Init hashtable to stock parameters
    $parameters = @{}

    # parse parameters
    if ($queryString -ne "") {
      $pairStrings = $queryString.Split('&')

      foreach ($pairString in $pairStrings) {
        $parts = $pairString.Split('=')
        if ($parts.Length -ge 2) {
          # Decode the key from URL encoding
          $key = [System.Web.HttpUtility]::UrlDecode($parts[0])
          # Join the remaining parts to handle values with '=' signs and decode from URL encoding
          $value = [System.Web.HttpUtility]::UrlDecode(($parts | Select-Object -Skip 1) -join '=')

          # Specific logic for the 'url' parameter to handle quotes
          if ($key -eq 'url') {
            # Check and remove single quotes if present around the value
            if ($value.StartsWith("'") -and $value.EndsWith("'") -and $value.Length -ge 2) {
              $value = $value.Substring(1, $value.Length - 2)
            }
          }
          # Add key-value pair to parameters if the value is not null or empty
          if ($null -ne $value -and $value -ne "") {
            $parameters[$key] = $value
          }
        }
      }
    }

    Write-Host "URL parameters :"
    $parameters.GetEnumerator() | ForEach-Object {
      Write-Host "  $($_.Key) = $($_.Value)" -ForegroundColor Gray
    }

    if ($parameters.ContainsKey('type')) {
      $global:TYPE = $($parameters['type'])
    }
    else {
      TerminateWithError -errorMessage "[type] parameter is missing. It is required to tell yt-dlp what streams he has to download."
    }

  }
  catch {
    TerminateWithError -errorMessage "Error while processing URL" -exception $_.Exception
  }

  <#*==========================================================================
  * ℹ		CHECK YT-DLP INSTALLATION
  ===========================================================================#>
  WriteTitle "DOWNLOAD WITH YT-DLP"

  Test-YtdlInstallation

  <#*==========================================================================
  * ℹ		CHECK FFMPEG INSTALLATION
  ===========================================================================#>

  Test-FFmpegInstallation

  <#*==========================================================================
  * ℹ		TEST URL to download
  ===========================================================================#>

  if ($parameters.ContainsKey('url')) {
    $global:DL_URL = $($parameters['url'])
  }
  else {
    TerminateWithError -errorMessage "[url] parameter is missing. It is required to tell yt-dlp the download source."
  }

  # handle auto
  if ($TYPE -eq "auto") {
    Write-Host "- Mode : auto" -ForegroundColor Green

    # Check if $DL_URL is type : audio
    foreach ($audioPrefix in $autoAudio) {
      if ($DL_URL -like "$audioPrefix*") {
        $global:TYPE = "audio" # redefine type
        Write-Host "`tAudio detected because it matches $audioPrefix"
        break
      }
      else {
        $global:TYPE = "video" # redefine type
        Write-Host "`tVideo will be used because no audio pattern detected in URL."
      }
    }
  }


  <#*==========================================================================
  * ℹ		TEST DOWNLOAD DIR
  ===========================================================================#>
  if ($parameters.ContainsKey('dldir')) {
    $global:DL_DIR = $($parameters['dldir'])

    if (Test-Path -Path $DL_DIR -PathType Container) {
      Write-Host "- Download file in (unless if handled by YDL-UI.exe): $DL_DIR" -ForegroundColor Green
    }
    else {
      TerminateWithError -errorMessage "The DOWNLOAD_DIR set in yt-dlp userscript : `"$DL_DIR`" doesn’t exist."
    }
  }
  else {
    $global:DL_DIR = $FullDownloadDir
    if (Test-Path -Path $DL_DIR -PathType Container) {
      Write-Host "- Download file in (unless if handled by YDL-UI.exe): $DL_DIR" -ForegroundColor Green
    }
    else {
      Write-Host "`"$DL_DIR`" doesn’t exist. Let’s try to create it." -ForegroundColor Yellow

      try {
        # We use -Force to avoid errors if the folder already exists (optional if necessary)
        $NewFolder = New-Item -Path $FullDownloadDir -ItemType Directory -ErrorAction Stop
        Write-Host "Success: Folder created at `"$($NewFolder.FullName)`"" -ForegroundColor Green
      }
      catch {
        TerminateWithError -errorMessage "Failed to create the folder `"$DownloadFolderName`" in `"$DownloadsPath`"." -exception $_.Exception
      }
    }
  }

  $output = ""

  if ($useTitle) {
    $output = $DL_DIR + "/" + $templateNameTitle
  }
  else {
    $output = $DL_DIR + "/" + $templateNameChannel
  }

  <#*==========================================================================
  * ℹ		BUILD QUALITY OPTION
  ===========================================================================#>

  if ($parameters.ContainsKey('quality')) {
    $global:QUALITY = $($parameters['quality'])
  }
  else {
    $global:QUALITY = ""
  }


  switch ($TYPE) {
    "audio" {
      Write-Host "- Mode : audio" -ForegroundColor Green

      if (-not $QUALITY) {
        # When QUALITY is an empty string, download the best audio
        $global:options = @(
          "--extract-audio",
          "--output", "$output",
          $DL_URL
        )
      }
      elseif ($QUALITY -eq "forceMp3") {
        $global:options = @(
          "--extract-audio",
          "--audio-format", "mp3",
          "--audio-quality", "0",
          "--output", "$output",
          "--format", "bestaudio[ext=mp3]/bestaudio/bestvideo*+bestaudio",
          $DL_URL
        )
      }
      else {
        $global:options = @(
          "--extract-audio",
          "--output", "$output",
          "--format", "bestaudio*[ext=$QUALITY]/bestaudio/bestvideo*+bestaudio",
          $DL_URL
        )
      }
    }
    "video" {
      Write-Host "- Mode : video" -ForegroundColor Green

      if ($QUALITY) {
        if ($QUALITY -ieq "best") {
          $videoQuality = "bestvideo*+bestaudio/best"
        }
        else {
          $videoQuality = "bestvideo*[vcodec^=avc1][height<=$QUALITY]+bestaudio[acodec=mp4a]/bestvideo*[height<=$QUALITY]+bestaudio/best"
        }
      }
      $global:options = @(
        "--format", $videoQuality,
        "--merge-output-format", $videoContainer,
        "--output", "$output",
        $DL_URL
      )
    }
    "test" {
      Write-Host "- Mode : test" -ForegroundColor Green
      $IsTest = $true

      $global:options = @(
        "--skip-download",
        "--print", " ",
        "--print", "Title           : %(title)s",
        "--print", "Duration        : %(duration_string)s",
        "--print", "Uploader        : %(uploader)s",
        "--print", "Default Formats : %(format)s",
        "--list-formats",
        $DL_URL
      )
    }
    "showUI" {
      Write-Host "- Mode : showUI" -ForegroundColor Green

      # run YDL-UI.exe with url and exit
      Write-Host "Open URL with YDL-UI"

      if (Test-Path -Path $UI_Path -PathType Leaf) {
        Start-Process $UI_Path -ArgumentList $DL_URL
        exit
      }
      else {
        TerminateWithError -errorMessage "Can not find $UI_Path"
      }
    }
  }


  <#*==========================================================================
  * ℹ		TEST COOKIES
  ===========================================================================#>
  if ((-not $UseBrowserCookies) -and ($myCookies)) {
    # Test cookie path
    if (Test-Path -Path $myCookies) {
      Write-Host "`- Use user cookies from file" -ForegroundColor Green
    }
    else {
      Write-Host "The cookie file doesn’t exist and will not be used:`n   $myCookies" -ForegroundColor Yellow
      $myCookies = ""
    }
  }

  <#*==========================================================================
  * ℹ		BUILD COMMAND TO RUN
  ===========================================================================#>
  Write-Host "`nCOMMAND:" -ForegroundColor Cyan

  if ($UseBrowserCookies) {
    $options += @("--cookies-from-browser", "$browserCookies")
  }
  elseif ($myCookies) {
    $options += @("--cookies", "$myCookies")
  }

  if ($jsRuntime) {
    $options += @("--js-runtimes", $jsRuntime)
  }

  if (-not $IsTest) {
    # If video title contains a dot as last character, delete it
    $options += @("--replace-in-metadata", "title", '\.$', "")
    # escape every pwsh chars in title
    $options += @("--replace-in-metadata", "title", '&', "and")
    $options += @("--replace-in-metadata", "title", '\|', "-")
  }

  if ($SelectDownloadedFile -and -not $IsTest) {
    $options += @("--exec", 'pwsh -NoProfile -NonInteractive -Command "Start-Process explorer.exe -ArgumentList \"/select,`\"{}`\"\""')
  }

  if ($IsTest) {
    #  quote option value when it contains space
    $optionsString = ($global:options | ForEach-Object {
        if ($_ -like '* *' -or $_ -eq ' ') {
          '"' + $_ + '"'
        }
        else {
          $_
        }
      }) -join ' '
  }
  else {
    $optionsString = ($options) -join ' '
  }

  # To display the correct command so it can be copied by user and used elsewhere
  # we need to quote the output directory
  $pattern = '--output\s+(.+?)\s+http'
  $substitution = '--output "$1" http'

  $optionsString = $optionsString -replace $pattern, $substitution

  # we need to quote format
  $pattern = '--format\s+?(.+?)\s'
  $substitution = '--format "$1" '

  $optionsString = $optionsString -replace $pattern, $substitution

  if ($UseBrowserCookies) {
    # we need to quote --cookies-from-browser
    $pattern = '--cookies-from-browser\s+?(.+?)\s'
    $substitution = '--cookies-from-browser "$1" '

    $optionsString = $optionsString -replace $pattern, $substitution
  }

  if (($myCookies) -and (-not $UseBrowserCookies)) {
    $pattern = '--cookies\s+(.+?\.txt)'
    $substitution = '--cookies "$1"'
    $optionsString = $optionsString -replace $pattern, $substitution
  }

  if (-not $IsTest) {
    $pattern = '--replace-in-metadata\s+?(.+?)\s+(.+?\$)\s?'
    $substitution = '--replace-in-metadata "$1" "$2" ""'
    $optionsString = $optionsString -replace $pattern, $substitution

    $pattern = '--replace-in-metadata\s+?(title)\s+?(.+?)\s+(\S+)'
    $substitution = '--replace-in-metadata "$1" "$2" "$3"'
    $optionsString = $optionsString -replace $pattern, $substitution
  }

  if ($SelectDownloadedFile -and -not $IsTest) {
    $pattern = '--exec\s+(.+)'
    $substitution = '--exec ''$1'''
    $optionsString = $optionsString -replace $pattern, $substitution -replace ',\s+', ','
  }

  if ($debug) {
    Write-Host "`$options: $options`n" -ForegroundColor Cyan
    Write-Host "`$optionsString: $optionsString`n" -ForegroundColor Yellow
  }

  Write-Host "yt-dlp $optionsString`n" -ForegroundColor Magenta
  Write-Host "running command…(wait)`n" -ForegroundColor DarkGray

  if ($IsTest -or (-not $UseColorfulOutput)) {
    & yt-dlp $options
  }
  else {
    & yt-dlp $options 2>&1 | Out-ColoredLog
  }


  <#*==========================================================================
  * ℹ		OPEN DOWNLOAD DIR
  ===========================================================================#>
  if ($LASTEXITCODE -eq 0) {

    if (-not $IsTest) {
      Write-Host "`nOPEN OUTPUT DIRECTORY" -ForegroundColor Cyan
    }

    # Play a beep to notify
    [console]::beep(650, 1000)

    WriteTitle "SCRIPT ENDED WITH NO ERROR"

  }
  else {
    WriteTitle "SCRIPT ENDED WITH ERROR" -ForegroundColor Red
    TerminateWithError -errorMessage "yt-dlp terminate with error"
  }

  # Read-Host -Prompt "Press Enter to exit"

  exit 0
}

<#*==========================================================================
* ℹ		CHECK ADMIN PRIVILEGE FOR INSTALL/UNINSTALL
===========================================================================#>
# Check for admin privileges if -install, -uninstall, or no parameters
if (-not (Test-AdminPrivileges)) {
  Write-Warning "This script requires administrative privileges for installation or uninstallation."
  exit 1
}

<#*==========================================================================
* ℹ		HANDLE UNINSTALL PARAMETERS
===========================================================================#>
$ytdlKey = "Registry::HKEY_CLASSES_ROOT\$protocol"

if ($uninstall) {
  Show-Version

  WriteTitle "UNINSTALL"
  Write-Host "Uninstalling ytdl protocol handler..."

  try {
    Remove-Item -Path "$ytdlKey" -Recurse -Force -ErrorAction SilentlyContinue

    if (Test-Path -Path $ytdlKey) {
      throw "$ytdlKey could NOT be deleted"
    }
    else {
      Write-Host "$ytdlKey deleted from the registry" -ForegroundColor Yellow
      Write-Host "`nSuccessfully uninstalled." -ForegroundColor Green
    }
  }
  catch {
    TerminateWithError -errorMessage "Uninstall failed" -exception $_.Exception
  }
}

<#*==========================================================================
* ℹ		HANDLE INSTALL PARAMETERS
===========================================================================#>

if ($install) {
  Show-Version

  WriteTitle "INSTALL"
  Write-Host "Installing ytdl protocol handler...`n"

  # Abort if yt-dlp is not found in path
  Test-YtdlInstallation

  $scriptPath = $PSCommandPath
  Write-Host "Commands will be sent to:"
  Write-Host "$scriptPath" -ForegroundColor Cyan

  $ytDlpPath = Get-YtdlPath

  try {
    # Create or update ytdl registry key
    New-Item -Path $ytdlKey -Force | Out-Null
    Set-ItemProperty -Path $ytdlKey -Name "(Default)" -Value "URL:ytdl"
    Set-ItemProperty -Path $ytdlKey -Name "URL Protocol" -Value ""

    Write-Host "`n$ytdlKey " -NoNewline -ForegroundColor Green
    Write-Host "was added to the registry" -ForegroundColor Cyan


    # Configure DefaultIcon if yt-dlp is found
    if ($ytdlpPath) {
      New-Item -Path "$ytdlKey\DefaultIcon" -Force | Out-Null
      Set-ItemProperty -Path "$ytdlKey\DefaultIcon" -Name "(Default)" -Value """$ytdlpPath"",1"

      Write-Host "`nIcon using " -NoNewline -ForegroundColor Cyan
      Write-Host "$ytDlpPath " -NoNewline -ForegroundColor Green
      Write-Host "succesfully added to the registry" -ForegroundColor Cyan
    }

    # Create shell\open\command key
    New-Item -Path "$ytdlKey\shell\open\command" -Force | Out-Null
    Set-ItemProperty -Path "$ytdlKey\shell\open\command" -Name "(Default)" -Value $command

    Write-Host "`nCommand: " -NoNewline -ForegroundColor Cyan
    Write-Host "$command " -NoNewline -ForegroundColor Green
    Write-Host "succesfully added to the registry" -ForegroundColor Cyan

    Write-Host "`nINSTALLATION COMPLETE" -ForegroundColor Green
  }
  catch {
    TerminateWithError -errorMessage "Failed to add protocol '$protocol`://' into the registry" -Exception $_.Exception
  }
}
