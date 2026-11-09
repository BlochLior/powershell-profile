# ==============================================================================
# PowerShell Profile
# ==============================================================================

# --- Load Private/Work Functions (Not tracked in Git) ---
$privateProfile = Join-Path -Path (Split-Path -Path $PROFILE) -ChildPath 'private.ps1'
if (Test-Path $privateProfile) {
    . $privateProfile
}

# --- Environment Inits ---
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd | Out-String | Invoke-Expression
} else {
    Write-Warning "fnm not found. Skipping Node version manager initialization."
}

# --- Shell Autocomplete & Predictions ---
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle Inline
    Set-PSReadLineOption -Colors @{ InlinePrediction = "$([char]0x1b)[38;5;244m" }

    # Toggle prediction layout with F2
    Set-PSReadLineKeyHandler -Key F2 -ScriptBlock {
        $options = Get-PSReadLineOption
        if ($options.PredictionViewStyle -eq 'Inline') {
            Set-PSReadLineOption -PredictionViewStyle ListView
        } else {
            Set-PSReadLineOption -PredictionViewStyle Inline
        }
    }
}

# --- Module Imports ---
$requiredModules = @('posh-git', 'Terminal-Icons')
foreach ($mod in $requiredModules) {
    if (Get-Module -ListAvailable -Name $mod) {
        Import-Module $mod
    } else {
        Write-Warning "Recommended module '$mod' not found. Run: Install-Module $mod"
    }
}

if (Get-Module -Name posh-git) {
    $GitPromptSettings.EnableFileStatus = $false
}

if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# --- Custom Navigation & Utility ---
# Update these paths to match your own directory structure
function cdw { Set-Location "~\dev\work" }
function cdu { Set-Location "~\dev\university" }

function bashrc { cursor $PROFILE }
Set-Alias -Name psprofile -Value bashrc

# Template for switching JDKs via Scoop (Update paths for your system)
function setjdk {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("17", "21")]
        [string]$Version
    )

    $jdk17 = "$HOME\scoop\apps\temurin17-jdk\current"
    $jdk21 = "$HOME\scoop\apps\temurin21-jdk\current"

    if (!(Test-Path $jdk17) -or !(Test-Path $jdk21)) {
        Write-Warning "JDK paths not found. Please update the scoop paths in the setjdk function."
        return
    }

    if ($Version -eq "17") {
        $env:JAVA_HOME = $jdk17
        Write-Host "`n ☕ Switched to Java 17`n" -ForegroundColor Cyan
    } else {
        $env:JAVA_HOME = $jdk21
        Write-Host "`n ☕ Switched to Java 21`n" -ForegroundColor Green
    }

    $cleanPath = ($env:PATH -split ';' | Where-Object { 
        $_ -ne "$jdk17\bin" -and $_ -ne "$jdk21\bin" 
    }) -join ';'
    
    $env:PATH = "$env:JAVA_HOME\bin;$cleanPath"
    java -version
}

# --- Eza Enhancements ---
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls { eza --icons --group-directories-first $args }
    function ll { eza -l --no-permissions --icons --header --git --group-directories-first $args }
    function la { eza -la --no-permissions --icons --header --git --group-directories-first $args }
    function lt { eza --tree --level=2 --icons --group-directories-first $args }
    function llt { eza -l --tree --level=2 --no-permissions --icons --git --group-directories-first $args }
    function l { eza --grid --across --icons --group-directories-first $args }
} else {
    Write-Warning "'eza' not found. Modern 'ls' aliases skipped. Run: scoop install eza"
}

# --- Custom Colorful Prompt ---
function prompt {
    $lastCommandSuccessful = $?
    
    $lastHistory = Get-History -Count 1
    $execTime = ""
    if ($lastHistory) {
        $duration = $lastHistory.EndExecutionTime - $lastHistory.StartExecutionTime
        if ($duration.TotalSeconds -ge 1) {
            if ($duration.TotalMinutes -ge 1) {
                $execTime = " ⏳ $([math]::Floor($duration.TotalMinutes))m $(($duration.Seconds))s"
            } else {
                $execTime = " ⏳ $($duration.TotalSeconds.ToString('F1'))s"
            }
        }
    }

    $currentTime = Get-Date -Format "HH:mm:ss"
    $currentPath = (Get-Location).Path -replace [regex]::Escape($HOME), '~'

    $ESC     = [char]27
    $Magenta = "$ESC[38;5;207m"
    $Cyan    = "$ESC[38;5;51m"
    $Green   = "$ESC[38;5;46m"
    $Red     = "$ESC[38;5;196m"
    $Yellow  = "$ESC[38;5;226m"
    $Gray    = "$ESC[38;5;244m"
    $Reset   = "$ESC[0m"

    $venv = ""
    if ($env:CONDA_DEFAULT_ENV) {
        $venv = "$Yellow($env:CONDA_DEFAULT_ENV) "
    } elseif ($env:VIRTUAL_ENV) {
        $venvName = Split-Path $env:VIRTUAL_ENV -Leaf
        $venv = "$Yellow($venvName) "
    }

    Write-Host "`n$Magenta╭─ $Gray[$currentTime] $venv$Cyan$currentPath$Yellow$execTime " -NoNewline
    
    if (Get-Module -Name posh-git) {
        Write-VcsStatus
    }

    $arrowColor = if ($lastCommandSuccessful) { $Green } else { $Red }
    return "`n$Magenta╰─$arrowColor ❯ $Reset"
}

# --- Project Management Template ---
# A generalized template for full-stack project commands
# One can adapt this to their own project structure by updating the projectBase variable,
# and by updating the commands for the different project types.
function Manage-Project {
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("runserver", "runclient", "testserver", "testclient", "migrate", "help")]
        [string]$Command = "help"
    )

    # Base path for the project (Update this to your actual project folder)
    $projectBase = "~\dev\my-project"

    switch ($Command) {
        "runserver" {
            Set-Location "$projectBase\server"
            # Example: conda activate myenv
            # python manage.py runserver
        }
        "runclient" {
            Set-Location "$projectBase\client"
            $env:BROWSER = "none"
            Start-Process "chrome" "http://localhost:3000"
            npm start
        }
        "testserver" {
            Set-Location "$projectBase\server"
            # python manage.py test
        }
        "testclient" {
            Set-Location "$projectBase\client"
            $env:CI = "true"
            npm test
        }
        "migrate" {
            Set-Location "$projectBase\server"
            # python manage.py migrate
        }
        "help" {
            Write-Host "`n 🎯 Project Shortcuts:" -ForegroundColor Cyan
            Write-Host " ----------------------------" -ForegroundColor DarkGray
            Write-Host " Manage-Project runserver  " -ForegroundColor Green -NoNewline
            Write-Host "- Starts the backend server"
            Write-Host " Manage-Project runclient  " -ForegroundColor Green -NoNewline
            Write-Host "- Starts the frontend client in Chrome"
            Write-Host " Manage-Project testserver " -ForegroundColor Yellow -NoNewline
            Write-Host "- Runs backend tests"
            Write-Host " Manage-Project testclient " -ForegroundColor Yellow -NoNewline
            Write-Host "- Runs frontend tests in CI mode"
            Write-Host " Manage-Project migrate    " -ForegroundColor Green -NoNewline
            Write-Host "- Runs database migrations`n"
        }
    }
}