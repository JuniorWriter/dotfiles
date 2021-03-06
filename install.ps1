$ErrorActionPreference = "Stop"

$CONFIG = "install.conf.yaml"
$DOTBOT_DIR = "dotbot"

$DOTBOT_BIN = "bin/dotbot"
$BASEDIR = $PSScriptRoot

Set-Location $BASEDIR
git -C $DOTBOT_DIR submodule sync --quiet --recursive
git submodule update --init --recursive $DOTBOT_DIR

foreach ($PYTHON in ('python', 'python3', 'python2')) {
    # Python redirects to Microsoft Store in Windows 10 when not installed
    if (& { $ErrorActionPreference = "SilentlyContinue"
            ![string]::IsNullOrEmpty((&$PYTHON -V))
            $ErrorActionPreference = "Stop" }) {
        &$PYTHON $(Join-Path $BASEDIR -ChildPath $DOTBOT_DIR | Join-Path -ChildPath $DOTBOT_BIN) -d $BASEDIR -c $CONFIG $Args
        Start-Prompt
        return
    }
}
Write-Error "Error: Cannot find Python."

function Install-Animation($program) {
    Write-Host -NoNewline "Installing $($program)" -ForegroundColor White
    Start-Sleep -Milliseconds 400
    Write-Host -NoNewline "."
    Start-Sleep -Milliseconds 400
    Write-Host -NoNewline "."
    Start-Sleep -Milliseconds 400
    Write-Host "."
}

function Start-Prompt {
    Clear-Host
    $dot_files_msg = Get-Content img/dotfiles
    Write-Output $dot_files_msg
    Write-Output "
                                 ....::::
                         ....::::::::::::
                ....:::: ::::::::::::::::
        ....:::::::::::: ::::::::::::::::
        :::::::::::::::: ::::::::::::::::
        :::::::::::::::: ::::::::::::::::
        :::::::::::::::: ::::::::::::::::
        :::::::::::::::: ::::::::::::::::
        ................ ................
        :::::::::::::::: ::::::::::::::::
        :::::::::::::::: ::::::::::::::::
        :::::::::::::::: ::::::::::::::::
        '''':::::::::::: ::::::::::::::::
                '''':::: ::::::::::::::::
                         ''''::::::::::::
                                 '''':::: POWERSHELL VERSION

"
    Write-Host -NoNewline "Starting installation" -ForegroundColor White
    Start-Sleep -Milliseconds 400
    Write-Host -NoNewline "."
    Start-Sleep -Milliseconds 400
    Write-Host -NoNewline "."
    Start-Sleep -Milliseconds 400
    Write-Host "."
    Start-Sleep -s 1
    Install-Packages
}

function Install-Packages {
    try {
        choco --version
    }
    catch {
        Install-Animation("Chocolatey")
    }

    # Scoop package manager installation
    try {
        scoop --version
        Clear-Host
    }
    catch {
        Install-Animation("Scoop")
        Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
        # Set-ExecutionPolicy RemoteSigned -scope CurrentUser -Force
    }

    # Install cargo
    try {
        cargo --version
    }
    catch {
        Write-Host "Cargo is not installed." -ForegroundColor Red
        try {
            Install-Animation("Cargo")
            choco install rust -y
        } catch {
            Write-Host "Installation failed" -ForegroundColor Red
            Write-Host "" -ForegroundColor Red
            Write-Host "Install it and try again." -ForegroundColor White
            Start-Sleep -Milliseconds 800
            exit 1
        }
    }
    Clear-Host

    # Check for git installed
    try {
        git --version
        Clear-Host
    }
    catch {
        # Install git
        # Get latest download url for git-for-windows 64-bit exe
        Install-Animation("git")
        $git_url = "https://api.github.com/repos/git-for-windows/git/releases/latest"
        $asset = Invoke-RestMethod -Method Get -Uri $git_url | ForEach-Object assets | Where-Object name -like "*64-bit.exe"
        # Download installer
        $installer = "$env:temp\$($asset.name)"
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer
        # Run installer
        $git_install_inf = "<install inf file>"
        $install_args = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /LOADINF=""$git_install_inf"""
        Start-Process -FilePath $installer -ArgumentList $install_args -Wait

        # Restart shell
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        Get-ExecutionPolicy
    }


    Install-Animation("packages")
    # Powershell plugins
    # Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    Install-Module posh-git -Scope CurrentUser -Force
    Install-Module oh-my-posh -Scope CurrentUser -Force

    # nvim installation
    scoop install neovim
    scoop install sudo

    # Check the if powershell profile exists
    if (!(Test-Path $Profile)) { New-Item -Path $Profile -Type File -Force }

    # Powershell theme
    # $omp_version = "2.0.492"
    # Copy-Item windows/terminal/powershell_config/Custom-theme.psm1 $HOME/Documents/WindowsPowerShell/Modules/oh-my-posh/$omp_version/Themes/
    # Copy-Item windows/terminal/powershell_config/Microsoft.PowerShell_profile.ps1 $HOME/Documents/WindowsPowerShell/
    # Copy-Item .config/nvim/ $HOME/AppData/Local/

    # Cargo packages installation
    cargo install bat
    cargo install --git https://github.com/zkat/exa --force
}
