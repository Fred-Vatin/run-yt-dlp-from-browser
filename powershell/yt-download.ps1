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

# Uncomment to display the debug message
# $DebugPreference = 'Continue'


$ScriptVersion = "2.5.0"

<#*==========================================================================
* ℹ		FUNCTIONS THAT NEED PRIORITY
===========================================================================#>
function Play-Sound {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateSet('Success', 'Error')]
    [string]$Action
  )

  process {
    # Fallback trigger flag
    $useFallback = $false

    if ($IsWindows -and -not [string]::IsNullOrEmpty($Action)) {
      # Assign modern Windows 11 system sounds based on action
      # Check the wav files in "C:\Windows\Media"
      # For Success, try:
      # chimes, Ring06, tada, Windows Background, Windows Exclamation, Windows Message Nudge, Windows Notify, Windows Notify System Generic, Windows Print complete
      # For Error, try:
      # ringout, Windows Ringout, chord, notify, Windows Ding, Windows Error
      $wavFile = if ($Action -eq 'Success') { 'Windows Print complete' } else { 'notify' }
      $wavPath = Join-Path -Path $env:WinDir -ChildPath "Media", $wavFile
      $wavPath = [System.IO.Path]::ChangeExtension($wavPath, ".wav")

      if (Test-Path $wavPath) {
        try {
          $player = New-Object System.Media.SoundPlayer($wavPath)
          $player.Play()
        }
        catch {
          $useFallback = $true
        }
      }
      else {
        $useFallback = $true
      }
    }
    else {
      # Trigger fallback if Unix or if no argument is passed
      $useFallback = $true
    }

    # Global multiplatform fallback
    if ($useFallback) {
      try {
        [System.Console]::Write([char]7)
      }
      catch {
        Write-Debug "Audio alert not supported on this host: $_"
      }
    }
  }
}

function TerminateWithError {
  param (
    [string]$ErrorMessage = "Error happened",
    [System.Management.Automation.ErrorRecord]$ErrorRecord
  )

  if ($PlaySound) {
    Play-Sound -Action Error
  }

  # Repeats the character 50 times to create a separator line
  $Line = '-' * 50

  if ($ErrorRecord) {
    Write-Host "`n$Line" -ForegroundColor Red
    Write-Host "`t❌  $ErrorMessage  ❌" -ForegroundColor Red
    Write-Host "$Line" -ForegroundColor Red


    # Step 1: Display primary exception with target command name if available
    $currentException = $ErrorRecord.Exception
    $primaryLine = $ErrorRecord.InvocationInfo.ScriptLineNumber

    $invocationName = $null
    if ($ErrorRecord.InvocationInfo) {
      if ($ErrorRecord.InvocationInfo.InvocationName) {
        $invocationName = $ErrorRecord.InvocationInfo.InvocationName
      }
      elseif ($ErrorRecord.InvocationInfo.MyCommand) {
        $invocationName = $ErrorRecord.InvocationInfo.MyCommand.Name
      }
    }

    # Fallback for primary ActionPreferenceStopException to catch the root cmdlet name
    if (-not $invocationName -and $ErrorRecord.Exception -and $ErrorRecord.Exception.PSObject.Properties['ErrorRecord']) {
      $nestedRecord = $ErrorRecord.Exception.ErrorRecord
      if ($nestedRecord -and $nestedRecord.InvocationInfo) {
        if ($nestedRecord.InvocationInfo.MyCommand) {
          $invocationName = $nestedRecord.InvocationInfo.MyCommand.Name
        }
        elseif ($nestedRecord.InvocationInfo.InvocationName) {
          $invocationName = $nestedRecord.InvocationInfo.InvocationName
        }
      }
    }

    if ($primaryLine) {
      Write-Host "Error at line: $primaryLine" -ForegroundColor Red
    }

    $lastMessage = $null
    if ($currentException) {
      # Prefix the command name to match native PowerShell behavior
      if ($invocationName) {
        Write-Host "${invocationName}: " -NoNewline
        Write-Host "$($currentException.Message)" -ForegroundColor Yellow
      }
      else {
        Write-Host "$($currentException.Message)" -ForegroundColor Yellow
      }
      $lastMessage = $currentException.Message
    }

    # Step 2: Traverse inner exceptions with deduplication logic
    while ($currentException.InnerException) {
      $parentException = $currentException
      $currentException = $currentException.InnerException

      $innerLine = $null
      $innerTargetCommand = $null

      # Prioritize custom attached PSErrorRecord because it contains the rich catch-block context
      $targetRecord = $null
      if ($parentException -and $parentException.PSObject.Properties['PSErrorRecord']) {
        $targetRecord = $parentException.PSErrorRecord
      }
      elseif ($currentException.PSObject.Properties['PSErrorRecord']) {
        $targetRecord = $currentException.PSErrorRecord
      }
      elseif ($currentException.ErrorRecord) {
        $targetRecord = $currentException.ErrorRecord
      }

      if ($targetRecord) {
        if ($targetRecord.InvocationInfo) {
          $innerLine = $targetRecord.InvocationInfo.ScriptLineNumber
          if ($targetRecord.InvocationInfo.MyCommand) {
            $innerTargetCommand = $targetRecord.InvocationInfo.MyCommand.Name
          }
          elseif ($targetRecord.InvocationInfo.InvocationName) {
            $innerTargetCommand = $targetRecord.InvocationInfo.InvocationName
          }
        }

        # Fallback for ActionPreferenceStopException where the actual cmdlet name is inside the exception's own ErrorRecord
        if (-not $innerTargetCommand -and $targetRecord.Exception -and $targetRecord.Exception.PSObject.Properties['ErrorRecord']) {
          $nestedRecord = $targetRecord.Exception.ErrorRecord
          if ($nestedRecord -and $nestedRecord.InvocationInfo) {
            if ($nestedRecord.InvocationInfo.MyCommand) {
              $innerTargetCommand = $nestedRecord.InvocationInfo.MyCommand.Name
            }
            elseif ($nestedRecord.InvocationInfo.InvocationName) {
              $innerTargetCommand = $nestedRecord.InvocationInfo.InvocationName
            }
          }
        }
      }

      # Deduplicate: skip if the message is identical and provides no new line context
      if ($currentException.Message -eq $lastMessage -and -not $innerLine) {
        continue
      }

      Write-Host "`n-> Caused by inner exception:" -ForegroundColor DarkGray
      if ($innerLine) {
        Write-Host "Error at line: $innerLine" -ForegroundColor Red
      }

      if ($innerTargetCommand) {
        Write-Host "${innerTargetCommand}: " -NoNewline
        Write-Host "$($currentException.Message)" -ForegroundColor Yellow
      }
      else {
        Write-Host "$($currentException.Message)" -ForegroundColor Yellow
      }
      $lastMessage = $currentException.Message
    }

    # Step 3: Display the script call stack to expose the calling function context
    if ($ErrorRecord.ScriptStackTrace) {
      Write-Host "`nScript Call Stack:" -ForegroundColor DarkGray
      $ErrorRecord.ScriptStackTrace -split "`r?`n" | Where-Object { $_.Trim() } | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
      }
    }

    Write-Host "`nEXIT  " -ForegroundColor Red
  }
  else {
    Write-Host "`n$Line" -ForegroundColor Red
    Write-Host "`t❌  ERROR  ❌" -ForegroundColor Red
    Write-Host "$Line" -ForegroundColor Red

    Write-Host "$ErrorMessage" -ForegroundColor Yellow
    Write-Host "`nEXIT  " -ForegroundColor Red
  }

  exit 1
}

function Get-OSDownloadPath {
  [CmdletBinding()]
  [OutputType([string])]
  param()

  $registryPath = $null
  $guidKey = $null
  $rawPath = $null
  $downloadsPath = $null

  Write-Debug "Get-OSDownloadPath starting…"

  if ($IsWindows) {
    Write-Debug "Operating System detected: Windows"
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    $guidKey = "{374DE290-123F-4565-9164-39C4925E467B}"

    if (Test-Path -Path $registryPath) {
      $rawPath = (Get-ItemPropertyValue -Path $registryPath -Name $guidKey -ErrorAction SilentlyContinue)
      Write-Debug "Registry raw value retrieved: $rawPath"

      if ($rawPath) {
        $downloadsPath = [Environment]::ExpandEnvironmentVariables($rawPath)
        Write-Debug "Expanded environment variables path: $downloadsPath"
      }
    }
  }
  elseif ($IsLinux -or $IsMacOS) {
    Write-Debug "Operating System detected: Linux/MacOS"
    $downloadsPath = Join-Path -Path $HOME -ChildPath "Downloads"
  }

  if (-not $downloadsPath) {
    Write-Debug "No download path resolved yet. Falling back to default user profile subfolder."
    $downloadsPath = Join-Path -Path $HOME -ChildPath "Downloads"
  }

  Write-Debug "Checking if path exists physically: $downloadsPath"
  if ($downloadsPath -and (Test-Path -Path $downloadsPath -PathType Container)) {
    Write-Debug "Path exists and is valid."
    return $downloadsPath
  }

  Write-Debug "Path does not exist or is invalid. Returning `$null`."
  return $null
}
<#*==========================================================================
*	ℹ		PARAMETERS

  Run the script with the -help parameter to know how to use it
=============================================================================
* ℹ                   DEFAULT VARIABLES
===========================================================================#>
# import user config
try {
  $ConfigPath = Join-Path $PSScriptRoot "config.ps1"
  if (Test-Path $ConfigPath) {
    . $ConfigPath
  }
  else {
    Start-Process "https://github.com/Fred-Vatin/run-yt-dlp-from-browser/wiki/How-to-setup-and-use%E2%80%AF%3F"
    TerminateWithError -errorMessage "`"config.ps1`" is missing."
  }
}
catch {
  Start-Process "https://github.com/Fred-Vatin/run-yt-dlp-from-browser/wiki/How-to-setup-and-use%E2%80%AF%3F"
  TerminateWithError -errorMessage "`"config.ps1`" is missing or can not be loaded."
}

# Don’t edit this part unless you know what you do.
# Get default downloads dir for each platform
$OS_DownloadPath = Get-OSDownloadPath
if (-not $DownloadsPath) {

  $DownloadsPath = $OS_DownloadPath

  if (-not $DownloadsPath) {
    $Local:ErrorMessage = @"
Can not get the user default Download directory.
Run the script in debug mode and open an issue.
You can try to set the DownloadsPath in your `"config.ps1`" file.
"@
    TerminateWithError -ErrorMessage "$Local:ErrorMessage"
  }
}
else {
  # Check if the DownloadsPath set in config.ps1 exists
  if (-not (Test-Path -Path $DownloadsPath -PathType Container)) {
    $Local:ErrorMessage = @"
`"$DownloadsPath`" : doesn’t exist.
You set a "DownloadsPath" which is invalid in your `"config.ps1`" file
Provide a valid path or
try to comment the line to use the user default Download directory.
"@
    TerminateWithError -ErrorMessage "$Local:ErrorMessage"
  }
}

$Defaults = @{
  autoAudio            = @("https://music.youtube.com/watch?v=")
  browserCookies       = "firefox"
  DownloadFolderName   = "yt-dlp"
  PlaySound            = $true
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
      $url = "${protocol}:?type=auto&url=$url"
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
      $script:TYPE = $($parameters['type'])
    }
    else {
      TerminateWithError -errorMessage "[type] parameter is missing. It is required to tell yt-dlp what streams he has to download."
    }

  }
  catch {
    TerminateWithError -errorMessage "Error while processing URL" -ErrorRecord $_
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
  * ℹ		TEST DOWNLOAD DIR
  ===========================================================================#>
  if ($parameters.ContainsKey('dldir')) {
    $script:DL_DIR = $($parameters['dldir'])

    if (Test-Path -Path $DL_DIR -PathType Container) {
      Write-Host "- Download file in (unless if handled by YDL-UI.exe): $DL_DIR" -ForegroundColor Green
    }
    else {
      Write-Host "The DOWNLOAD_DIR set in yt-dlp userscript (Tampermonkey) : `"$DL_DIR`" doesn’t exist." -ForegroundColor Yellow
      Write-Host "Trying fallback…" -ForegroundColor Yellow
      $Script:DOWNLOAD_DIR_fallback = $true
    }
  }
  if ($DOWNLOAD_DIR_fallback -or -not $parameters.ContainsKey('dldir')) {
    $script:DL_DIR = $FullDownloadDir
    if (Test-Path -Path $DL_DIR -PathType Container) {
      Write-Host "- Download file in (unless if handled by YDL-UI.exe): $DL_DIR" -ForegroundColor Green
    }
    else {
      Write-Host "`"$DL_DIR`" " -ForegroundColor Yellow
      Write-Host "doesn’t exist. Let’s try to create it."

      try {
        # We use -Force to avoid errors if the folder already exists (optional if necessary)
        $NewFolder = New-Item -Path $FullDownloadDir -ItemType Directory -ErrorAction Stop
        Write-Host " Success: Folder created at `"$($NewFolder.FullName)`"`n" -ForegroundColor Green
      }
      catch {
        TerminateWithError -errorMessage "Failed to create the folder `"$DownloadFolderName`" in `"$DownloadsPath`"." -ErrorRecord $_
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
  * ℹ		TEST URL to download
  ===========================================================================#>

  if ($parameters.ContainsKey('url')) {
    $script:DL_URL = $($parameters['url'])
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
        $script:TYPE = "audio" # redefine type
        Write-Host "`tAudio detected because it matches $audioPrefix"
        break
      }
      else {
        $script:TYPE = "video" # redefine type
        Write-Host "`tVideo will be used because no audio pattern detected in URL."
      }
    }
  }

  <#*==========================================================================
  * ℹ		BUILD QUALITY OPTION
  ===========================================================================#>

  if ($parameters.ContainsKey('quality')) {
    $script:QUALITY = $($parameters['quality'])
  }
  else {
    $script:QUALITY = ""
  }


  switch ($TYPE) {
    "audio" {
      Write-Host "- Mode : audio" -ForegroundColor Green

      if (-not $QUALITY) {
        # When QUALITY is an empty string, download the best audio
        $script:options = @(
          "--extract-audio",
          "--output", "$output",
          $DL_URL
        )
      }
      elseif ($QUALITY -eq "forceMp3") {
        $script:options = @(
          "--extract-audio",
          "--audio-format", "mp3",
          "--audio-quality", "0",
          "--output", "$output",
          "--format", "bestaudio[ext=mp3]/bestaudio/bestvideo*+bestaudio",
          $DL_URL
        )
      }
      else {
        $script:options = @(
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
      $script:options = @(
        "--format", $videoQuality,
        "--merge-output-format", $videoContainer,
        "--output", "$output",
        $DL_URL
      )
    }
    "test" {
      Write-Host "- Mode : test" -ForegroundColor Green
      $IsTest = $true

      $script:options = @(
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
  * ℹ		Handle select downloaded file in Windows
  ===========================================================================#>
  if ($IsWindows) {
    # Setting native Windows API via C#
    $Win32Signature = @'
[DllImport("shell32.dll", ExactSpelling = true)]
public static extern int SHParseDisplayName([MarshalAs(UnmanagedType.LPWStr)] string pszName, IntPtr pbc, out IntPtr ppidl, uint sfgaoIn, out uint psfgaoOut);

[DllImport("shell32.dll", ExactSpelling = true)]
public static extern int SHOpenFolderAndSelectItems(IntPtr pidlFolder, uint cidl, IntPtr[] apidl, uint dwFlags);

[DllImport("ole32.dll", ExactSpelling = true)]
public static extern void CoTaskMemFree(IntPtr pv);
'@

    $ShUtils = Add-Type -MemberDefinition $Win32Signature -Name "ShellUtils" -Namespace "Win32API" -PassThru

    function Show-InFileManager {
      [CmdletBinding()]
      param (
        [string]$FilePath
      )

      process {
        try {
          $AbsolutePath = (Resolve-Path -Path $FilePath -ErrorAction Stop).Path
          # 1. Obtenir le PIDL (Pointer to an Item ID List) du fichier ciblé
          $Pidl = [IntPtr]::Zero
          $SfgaoOut = 0
          $Result = $ShUtils::SHParseDisplayName($AbsolutePath, [IntPtr]::Zero, [ref]$Pidl, 0, [ref]$SfgaoOut)

          if ($Result -eq 0 -and $Pidl -ne [IntPtr]::Zero) {
            try {
              # 2. Appeler l'API native.
              [void]$ShUtils::SHOpenFolderAndSelectItems($Pidl, 0, $null, 0)
            }
            finally {
              # 3. Libérer la mémoire managée requise par l'API COM/Shell
              if ($Pidl -ne [IntPtr]::Zero) {
                $ShUtils::CoTaskMemFree($Pidl)
              }
            }
          }
          else {
            # Sécurité si l'API échoue : retour à la méthode basique
            Start-Process explorer.exe -ArgumentList "/select,`"$AbsolutePath`""
          }
        }
        catch {
          # Pass $_.Exception as the InnerException to preserve the original root cause
          $innerException = $_.Exception
          $outerException = New-Object System.Reflection.TargetInvocationException("File manager failed to open.", $innerException)

          # Attach the original ErrorRecord to the exception to preserve PowerShell context
          Add-Member -InputObject $outerException -NotePropertyName "PSErrorRecord" -NotePropertyValue $_

          throw $outerException
        }
      }

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
    # Important for the function Out-ColoredLog
    $options += @("--encoding", "utf-8")

    # If video title contains a dot as last character, delete it
    $options += @("--replace-in-metadata", "title", '\.$', "")
    # escape every pwsh chars in title
    $options += @("--replace-in-metadata", "title", '&', "and")
    $options += @("--replace-in-metadata", "title", '\|', "-")
  }

  if ($IsTest) {
    #  quote option value when it contains space
    $optionsString = ($script:options | ForEach-Object {
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

  if ($SelectDownloadedFile -and -not $IsTest -and $IsWindows) {
    # 1. Generate a unique temporary file path
    $TempPathFile = [System.IO.Path]::GetTempFileName()

    # 2. We use --exec to write the downloaded file path to our temporary file
    $options += @(
      "--exec", "pwsh -NoProfile -NonInteractive -Command `"Out-File -FilePath '$TempPathFile' -InputObject '{}' -Encoding utf8`""
    )
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
    # If we don’t set everything in utf-8, the $InputObject from pipeline will be corrupted
    # Check https://github.com/PowerShell/PowerShell/issues/25698#issuecomment-4599829781
    [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

    & yt-dlp $options 2>&1 | Out-ColoredLog
  }

  <#*==========================================================================
  * ℹ		OPEN DOWNLOAD DIR
  ===========================================================================#>
  if ($LASTEXITCODE -eq 0) {

    if (-not $IsTest) {

      if ($IsWindows -and $SelectDownloadedFile) {

        Write-Host "`nOPEN OUTPUT DIRECTORY" -ForegroundColor Cyan

        # Retrieve downloaded file path after execution
        if (Test-Path $TempPathFile) {
          $DownloadedFilePath = (Get-Content -Path $TempPathFile -Raw).Trim()
          Remove-Item -Path $TempPathFile -ErrorAction SilentlyContinue
        }

        # Apply file selection logic
        if ($DownloadedFilePath) {
          Write-Host "DownloadedFilePath : `"$DownloadedFilePath`"" -ForegroundColor Yellow
          try {
            Show-InFileManager -FilePath $DownloadedFilePath
          }
          catch {
            TerminateWithError -ErrorMessage "Show-InFileManager failed" -ErrorRecord $_
          }
        }
        else {
          TerminateWithError '$DownloadedFilePath was not find in $TempPathFile'
        }
      }
    }

    if ($PlaySound) {
      Play-Sound -Action Success
    }

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

  if ($IsWindows) {
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
  else {
    TerminateWithError -errorMessage "Sorry but this works only on Windows (for now)"
  }
}

<#*==========================================================================
* ℹ		HANDLE INSTALL PARAMETERS
===========================================================================#>

if ($install) {
  Show-Version

  WriteTitle "INSTALL"
  Write-Host "Installing ytdl protocol handler...`n"

  if ($IsWindows) {
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
      TerminateWithError -errorMessage "Failed to add protocol '$protocol`://' into the registry" -ErrorRecord $_
    }

  }
  else {
    TerminateWithError -errorMessage "Sorry but this works only on Windows (for now)"
  }

}
