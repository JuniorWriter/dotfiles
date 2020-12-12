function Start-Prompt() {
        Clear-Host
        $dot_files_msg = Get-Content installers/msg.txt
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
                                 ''''::::

"
        Start-Sleep -s 1
        Write-Host -NoNewline "Starting installation"
        Start-Sleep -Milliseconds 400
        Write-Host -NoNewline "."
        Start-Sleep -Milliseconds 400
        Write-Host -NoNewline "."
        Start-Sleep -Milliseconds 400
        Write-Host "."
        Start-Sleep -s 1
        Install-Packages
}

function Install-Packages() {
        try {
                cargo --version
        }
        catch {
                Write-Host "Installation failed" -ForegroundColor Red
                Write-Host "Cargo is not installed." -ForegroundColor Red
                Write-Host "" -ForegroundColor Red
                Write-Host "Install it and try again." -ForegroundColor White

                Start-Sleep -Milliseconds 800
                Start-Process "https://win.rustup.rs/"
                exit 1
        }
        Clear-Host
        Write-Host -NoNewline "Installing packages"
        Start-Sleep -Milliseconds 400
        Write-Host -NoNewline "."
        Start-Sleep -Milliseconds 400
        Write-Host -NoNewline "."
        Start-Sleep -Milliseconds 400
        Write-Host "."
        # Scoop package manager installation
        Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
        Set-ExecutionPolicy RemoteSigned -scope CurrentUser

        # Install git
        # Get latest download url for git-for-windows 64-bit exe
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
        
        # Powershell plugins
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Install-Module posh-git -Scope CurrentUser -Force
        Install-Module oh-my-posh -Scope CurrentUser -Force

        # Screen fetch
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted
        Install-Module -Name windows-screenfetch
        Import-Module windows-screenfetch

        # nvim installation
        scoop install neovim
        scoop instal sudo

        # Check the if powershell profile exists
        if (!(Test-Path $Profile)) { New-Item -Path $Profile -Type File -Force }
        
        # Powershell theme
        $omp_version = "2.0.492"
        Copy-Item windows/terminal/powershell_config/Custom-theme.psm1 $HOME/Documents/WindowsPowerShell/Modules/oh-my-posh/$omp_version/Themes/
        Copy-Item windows/terminal/powershell_config/Microsoft.PowerShell_profile.ps1 $HOME/Documents/WindowsPowerShell/
        Copy-Item .config/nvim/ $HOME/AppData/Local/

        # Cargo packages installation
        cargo install bat
        cargo install --git https://github.com/zkat/exa --force
}

Start-Prompt