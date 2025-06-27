<#*==========================================================================
*	ℹ		PARAMETERS

  Only one parameter: -url
  This url is then parsed and can contain those parameters:
  - type [string] (required)
    - "auto": if the url to download is detected as audio, download best audio
              if not, download the url using best video
    - "audio": download audio stream only or extract audio
    - "video": download video+audio stream as mp4 using $videoQuality
    - "test": display all available formats for the url and its title
    - "showUI": if YDL-UI.exe is installed and path set in this script, send url to it.
                Requires https://github.com/Maxstupo/ydl-ui/
  - quality [string] (optional)
    - "": default is empty and download the best quality audio and video
    - "1080, 720, etc.": use any height you want. It will try to download this video quality if exist or the next one below.
    - "forceMp3": if type is audio, download mp3 stream if exist or convert to mp3
    - "best, aac, m4a, mp3, opus, vorbis, wav": try to download this quality in priority, else find the other best audio stream.
  - dldir [string] (optional)
    - "directory/path": if not set in the -url, use the one set in this script
  - url [string] (required)
    - "url": to download
===========================================================================#>
param(
  [Parameter(Mandatory = $true)]
  [string]$url
)

<#*==========================================================================
* ℹ                   FUNCTIONS
===========================================================================#>
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
    Write-Host "$errorMessage :`n$($exception.Message)`nEXIT" -ForegroundColor Red
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

<#*==========================================================================
* ℹ                   DEFAULT VARIABLES
===========================================================================#>
New-Variable -Name protocol -Value "ytdl://"
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
<#*==========================================================================
* ℹ            GET PARAMETERS
===========================================================================#>
Clear-Host

Write-Host "`nScript called with argument = $url `n"

try {
  # Définir la longueur du préfixe "ytdl://download/?"
  # C'est la longueur de "ytdl://download/" (16) + le '?' (1) = 17 caractères
  $prefix = "${protocol}download/?"
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
if (Get-Command yt-dlp -ErrorAction SilentlyContinue) {
  WriteTitle "DOWNLOAD WITH YT-DLP"
}
else {
  TerminateWithError -errorMessage "yt-dlp n'est pas installé globalement sur le système. Installez-le ou ajoutez-le au PATH."
}
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
* ℹ		CHECK DOPUS INSTALLATION
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

