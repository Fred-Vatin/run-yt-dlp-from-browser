param(
  [switch]$install,
  [switch]$uninstall,
  [switch]$help,
  [switch]$man,
  [string]$url
)

# Stop the script if an error occurs.
$ErrorActionPreference = 'Stop'
<#*==========================================================================
*	ℹ		PARAMETERS

  Run the script with the -help parameter to know how to use it
===========================================================================#>

<#*==========================================================================
* ℹ                   DEFAULT VARIABLES
===========================================================================#>
New-Variable -Name format -Value "bestvideo[vcodec^=avc1]+bestaudio[ext=m4a]/best" -Option Constant
New-Variable -Name directory -Value "E:/OneDrive/Téléchargements/yt-dlp" -Option Constant
New-Variable -Name templateNameChannel -Value "%(uploader|)s%(uploader& - )s%(title).70s.%(ext)s"
New-Variable -Name templateNameTitle -Value "%(title).70s.%(ext)s"
# if useTitle is true then use $templateNameTitle else $templateNameChannel
New-Variable -Name useTitle -Value $true
New-Variable -Name myCookies -Value "D:/Programmes/Internet/youtube-dl/cookies.txt"
# defaut quality for video (make it compatible to upload on 𝕏)
New-Variable -Name videoQuality -Value "bestvideo[vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo+bestaudio"
# Videos will use this container
New-Variable -Name videoContainer -Value "mp4"
New-Variable -Name UI_Path -Value "D:/Programmes/Internet/youtube-dl/YDL-UI_Portable/YDL-UI.exe"
# set URLs for which the script will detect as audio
New-Variable -Name autoAudio -Value @("https://music.youtube.com/watch?v=")

# This is the command triggered by the protocol
# It open the Windows Terminal with the profile 'PowerShell 7' and this script with the given url
New-Variable -Name command -Value "cmd.exe /c wt.exe -p ""PowerShell 7"" -- pwsh.exe -NoExit -File ""$PSCommandPath"" -url ""%1"""

# ⚠	NON RECOMMENDED
# If for some reason, you would want to change the protocol name.
# But you will have to change the userscript run by your browser.
New-Variable -Name protocol -Value "ytdl"

New-Variable -Name repo -Value "https://github.com/Fred-Vatin/run-yt-dlp-from-browser" -Option Constant


<#*==========================================================================
* ℹ                   FUNCTIONS
===========================================================================#>
# Display help message with specified formatting
function Show-Help {
  Write-Host "ℹ`tPARAMETERS" -ForegroundColor Magenta
  Write-Host "========================`n" -ForegroundColor Magenta
  Write-Host "-man" -ForegroundColor Magenta
  Write-Host "`tUse this to open wiki at `"$repo`"`n"
  Write-Host "-install (default)" -ForegroundColor Magenta
  Write-Host "`tUse this to register the custom protocol `"$protocol`://`" in the registry that will run this script with the parameter -url when called`n"
  Write-Host "-uninstall" -ForegroundColor Magenta
  Write-Host "`tUse this to unregister the custom protocol `"$protocol`://`" from the registry`n"
  Write-Host "-url" -ForegroundColor Magenta
  Write-Host "`tThis url is parsed and can contain those parameters:"
  Write-Host "`n`t- type [string] (required)" -ForegroundColor Cyan
  Write-Host "`t`t`"auto`"`n`t`t`tif the url to download is detected as audio, download best audio"
  Write-Host "`t`t`tif not, download the url using best video"
  Write-Host "`n`t`t`"audio`"`n`t`t`tdownload audio stream only or extract audio"
  Write-Host "`n`t`t`"video`"`n`t`t`tdownload video+audio stream as mp4 using `$videoQuality"
  Write-Host "`n`t`t`"test`"`n`t`t`tdisplay all available formats for the url and its title"
  Write-Host "`n`t`t`"showUI`"`n`t`t`tif YDL-UI.exe is installed and path set in this script, send url to it."
  Write-Host "`t`t`tRequires https://github.com/Maxstupo/ydl-ui/"
  Write-Host "`n`tquality [string] (optional)" -ForegroundColor Cyan
  Write-Host "`t`t`"`"`n`t`t`tdefault is empty and download the best quality audio and video"
  Write-Host "`n`t`t`"1080`", `"720`", etc.`n`t`t`tuse any height you want. It will try to download this video quality if exist or the next one below."
  Write-Host "`n`t`t`"forceMp3`"`n`t`t`tif type is audio, download mp3 stream if exists or convert to mp3"
  Write-Host "`n`t`t`"best, aac, m4a, mp3, opus, vorbis, wav`"`n`t`t`ttry to download this quality in priority, else find the other best audio stream."
  Write-Host "`n`t- dldir [string] (optional)" -ForegroundColor Cyan
  Write-Host "`t`t`"directory/path`"`n`t`t`tif not set in the -url, use the one set in this script"
  Write-Host "`n`t- url [string] (required)" -ForegroundColor Cyan
  Write-Host "`t`t`"url`"`tto download"
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
    [string]$title
  )

  Write-Host "`n===== $title =====`n" -ForegroundColor Cyan
}

# Check if the script is running with administrative privileges
function Test-AdminPrivileges {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]$identity
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-YtdlInstallation {
  if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    TerminateWithError -errorMessage "yt-dlp is not installed globally on the system. Install it or add it to the PATH."
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

<#*==========================================================================
* ℹ            GET PARAMETERS
===========================================================================#>
Clear-Host

<#*==========================================================================
* ℹ		HANDLE HELP PARAMETER
===========================================================================#>

if ($help) {
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
  Write-Host "`nScript called with argument" -NoNewline
  Write-Host "-url" -ForegroundColor Magenta
  Write-Host "`t$url`n"

  try {
    # Définir la longueur du préfixe "ytdl://download/?"
    # C'est la longueur de "ytdl://download/" (16) + le '?' (1) = 17 caractères
    $prefix = "${protocol}://download/?"
    $prefixLength = $prefix.Length # Pour être sûr, on calcule dynamiquement

    # Extraire la chaîne de requête en fonction du préfixe
    if ($url.StartsWith($prefix)) {
      $queryString = $url.Substring($prefixLength)
    }
    else {
      TerminateWithError -errorMessage "L’url attendue doit commencer par: $prefix`n   Or l’url est: $url"
    }

    # Initialiser le hashtable pour stocker les paramètres
    $parameters = @{}

    # Parser la chaîne de requête extraite
    if ($queryString -ne "") {
      $pairStrings = $queryString.Split('&')

      foreach ($pairString in $pairStrings) {
        $parts = $pairString.Split('=')
        if ($parts.Length -ge 2) {
          # Utiliser -ge 2 pour gérer les cas avec "=" dans la valeur
          $key = [System.Web.HttpUtility]::UrlDecode($parts[0])
          # Joindre les parties restantes si la valeur contenait des signes '='
          $value = [System.Web.HttpUtility]::UrlDecode(($parts | Select-Object -Skip 1) -join '=')

          # **Logique spécifique pour le paramètre 'url' avec les guillemets**
          if ($key -eq 'url') {
            # Vérifier et retirer les guillemets simples s'ils sont présents
            if ($value.StartsWith("'") -and $value.EndsWith("'") -and $value.Length -ge 2) {
              $value = $value.Substring(1, $value.Length - 2)
            }
          }
          $parameters[$key] = $value
        }
        elseif ($parts.Length -eq 1) {
          $key = [System.Web.HttpUtility]::UrlDecode($parts[0])
          $parameters[$key] = "" # Paramètre sans valeur
        }
      }
    }

    Write-Host "Paramètres de l'URL :"
    $parameters.GetEnumerator() | ForEach-Object {
      Write-Host "  $($_.Key) = $($_.Value)" -ForegroundColor Gray
    }

    # Accès spécifique aux paramètres pour vérification
    if ($parameters.ContainsKey('type')) {
      $global:TYPE = $($parameters['type'])
    }
    else {
      TerminateWithError -errorMessage "Le paramètre [type] est manquant. Or il est requis pour indiquer à yt-dlp ce qu’il doit télécharger."
    }

  }
  catch {
    TerminateWithError -errorMessage "Erreur lors du traitement de l'URL" -exception $_.Exception
  }

  <#*==========================================================================
  * ℹ		CHECK YT-DLP INSTALLATION
  ===========================================================================#>
  WriteTitle "DOWNLOAD WITH YT-DLP"

  Test-YtdlInstallation

  <#*==========================================================================
  * ℹ		TEST URL to download
  ===========================================================================#>

  if ($parameters.ContainsKey('url')) {
    $global:DL_URL = $($parameters['url'])
  }
  else {
    TerminateWithError -errorMessage "Le paramètre [url] est manquant. Or il est requis pour indiquer à yt-dlp ce qu’il doit télécharger."
  }

  # handle auto
  if ($TYPE -eq "auto") {
    Write-Host "- Mode : auto" -ForegroundColor Green

    # Vérifier si $DL_URL est de type audio
    foreach ($prefix in $autoAudio) {
      if ($DL_URL -like "$prefix*") {
        $global:TYPE = "audio" # redéfinir type
        Write-Host "`tAudio détecté car correspond à $prefix"
        break
      }
      else {
        $global:TYPE = "video" # redéfinir type
        Write-Host "`tVidéo détectée car ne correspond à aucun pattern audio."
      }
    }
  }


  <#*==========================================================================
  * ℹ		TEST DOWNLOAD DIR
  ===========================================================================#>
  if ($parameters.ContainsKey('dldir')) {
    $global:DL_DIR = $($parameters['dldir'])
  }
  else {
    $global:DL_DIR = $directory
  }

  # Tester l'existence du dossier
  if (Test-Path -Path $DL_DIR -PathType Container) {
    Write-Host "- Download file in (unless if handled by YDL-UI.exe): $DL_DIR" -ForegroundColor Green
  }
  else {
    TerminateWithError -errorMessage "The $DL_DIR doesn’t exist."
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
    TerminateWithError -errorMessage "Le paramètre [quality] est manquant. Or, même s’il est vide, il est requis."
  }


  switch ($TYPE) {
    "audio" {
      Write-Host "- Mode : audio" -ForegroundColor Green

      if (-not $quality) {
        # Quand quality est une chaîne vide, télécharger le meilleur audio
        $global:options = @(
          "--extract-audio",
          "-o", $output,
          $DL_URL
        )
      }
      elseif ($quality -eq "forceMp3") {
        $global:options = @(
          "--extract-audio",
          "--audio-format", "mp3",
          "--audio-quality", "0",
          "-o", $output,
          "-f", "bestaudio[ext=mp3]/bestaudio/bestvideo+bestaudio",
          $DL_URL
        )
      }
      else {
        $global:options = @(
          "--extract-audio",
          "-o", $output,
          "-f", "bestaudio[ext=$quality]/bestaudio/bestvideo+bestaudio",
          $DL_URL
        )
      }
    }
    "video" {
      Write-Host "- Mode : video" -ForegroundColor Green

      if ($quality) {
        $videoQuality = "bestvideo[vcodec^=avc1][height<=$quality]+bestaudio[ext=m4a]/bestvideo[height<=$quality]+bestaudio"
      }
      $global:options = @(
        "-f", $videoQuality,
        "--merge-output-format", $videoContainer,
        "-o", $output,
        $DL_URL
      )
    }
    "test" {
      Write-Host "- Mode : test" -ForegroundColor Green

      $global:options = @(
        "--skip-download",
        "--get-title",
        "--list-formats",
        $DL_URL
      )
    }
    "showUI" {
      Write-Host "- Mode : showUI" -ForegroundColor Green

      # run YDL-UI.exe with url and exit
      Write-Host "Ouverture de l’URL avec YDL-UI"

      if (Test-Path -Path $UI_Path -PathType Leaf) {
        Start-Process $UI_Path -ArgumentList $DL_URL
        exit
      }
      else {
        TerminateWithError -errorMessage "L'exécutable $UI_Path n'existe pas."
      }
    }
  }


  <#*==========================================================================
  * ℹ		TEST COOKIES
  ===========================================================================#>
  # Tester l'existence du fichier
  if (Test-Path -Path $myCookies) {
    Write-Host "`- Use user cookies from file" -ForegroundColor Green
  }
  else {
    Write-Host "The cookie file doesn’t exist and will not be used:`n   $myCookies" -ForegroundColor Yellow
    $myCookies = ""
  }

  <#*==========================================================================
  * ℹ		BUILD COMMAND TO RUN
  ===========================================================================#>
  Write-Host "`nCOMMAND:" -ForegroundColor Cyan

  if ($myCookies) {
    Write-Host "yt-dlp $options --cookies `"$myCookies`"`n" -ForegroundColor Magenta
    Write-Host "running command…(wait)`n" -ForegroundColor DarkGray
    & yt-dlp $options --cookies "$myCookies"
  }
  else {
    Write-Host "yt-dlp $options`n" -ForegroundColor Magenta
    Write-Host "running command…(wait)`n" -ForegroundColor DarkGray
    & yt-dlp $options
  }

  <#*==========================================================================
  * ℹ		OPEN DOWNLOAD DIR
  ===========================================================================#>
  if ($TYPE -ne "test") {
    Write-Host "`nOPEN OUTPUT DIRECTORY" -ForegroundColor Cyan
    try {
      # Ouvrir le dossier de téléchargement
      Invoke-Item -Path $DL_DIR
    }
    catch {
      TerminateWithError "Invoke-Item -Path $DL_DIR [failed]"
    }

    # Émettre une notification sonore
    [console]::beep(650, 1000)
  }
  WriteTitle "SCRIPT ENDED WITH NO ERROR"

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
  WriteTitle "UNINSTALL"
  Write-Host "Uninstalling ytdl protocol handler..."

  try {
    Remove-Item -Path "$ytdlKey" -Recurse -Force -ErrorAction SilentlyContinue

    if (Test-Path -Path $ytdlKey) {
      Throw "$ytdlKey could NOT be deleted"
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

else {
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
