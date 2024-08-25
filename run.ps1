param(
    [string[]] $reconfigure = "",
    [switch] $help
)

if ($help.IsPresent)
{
    Write-Host "`nAvailable arguments:`n" -ForegroundColor Yellow
    Write-Host "    -reconfigure [string]       Used for configuring individual options in json file."
    Write-Host "                                    - Spt-Launcher-Path" -ForegroundColor DarkGray
    Write-Host "                                    - Spt-Server-Ip" -ForegroundColor DarkGray
    Write-Host "                                    - Keep-Tailscale-On" -ForegroundColor DarkGray
    Write-Host "                                    - All`n" -ForegroundColor DarkGray
    Write-Host "    -help                       Used for showing this menu`n"
    exit
}

if (-not $reconfigure.IsPresent)
{
    Write-Host "Checking for config.json file..." -ForegroundColor DarkBlue
}

if (-not (Test-Path .\config.json))
{
    Write-Warning "Config file doesn't exist, creating default one"
    '{"first_run":  true,"spt_launcher_path":  "","spt_server_ip":  "","keep_tailscale_on":  "False","is_tailscale_instaled":  "False","show_guide":  "True","is_udp_port_open":  "False","auth_key": ""}' >> config.json
    if (Test-Path .\config.json)
    {
        Write-Host "Config file successfuly created`n" -ForegroundColor DarkGreen
    }
}
else {
    Write-Host "Found config file`n" -ForegroundColor DarkGreen
}

$json = Get-Content -Raw .\config.json | ConvertFrom-Json

if ($reconfigure.Contains("All"))
{
    $json.spt_launcher_path = ""
    $json.spt_server_ip = ""
    $json.keep_tailscale_on = ""
}

if ($json.spt_launcher_path -eq "" -or -not (Test-Path -Path $json.spt_launcher_path) -or $reconfigure.Contains("Spt-Launcher-Path"))
{
    Write-Warning "The path to SPT is blank or invalid"
    $json.spt_launcher_path = ""
    do
    {
        $spt_launcher_path = Read-Host "Enter the path to the folder containing the 'SPT.Launcher.exe' file"
        $json.spt_launcher_path = $spt_launcher_path
        $spt_launcher_path += "\SPT.Launcher.exe"
        
        if (-not (Test-Path -Path $spt_launcher_path))
        {
            Write-Error "The Path is not valid or doesn't end in directory with 'SPT.Launcher.exe' file"
        }

    }while(-not (Test-Path -Path $spt_launcher_path))

    Write-Host "Path set successfuly `n" -ForegroundColor DarkGreen
}
else {
    Write-Host "Path is set" -ForegroundColor DarkGreen
}

if ($json.spt_server_ip -eq "" -or $reconfigure.Contains("Spt-Server-Ip"))
{
    Write-Warning "The IP address of the SPT server is blank or invalid"
    $json.spt_server_ip = ""
    do
    {
        $spt_server_ip = Read-Host "Enter the IP address of the SPT server below"
        $json.spt_server_ip = $spt_server_ip

        if ($json.spt_server_ip -eq "")
        {
            Write-Error "IP cannot be blank"
        }

    }while($json.spt_server_ip -eq "")

    Write-Host "IP set successfuly `n" -ForegroundColor DarkGreen
}
else {
    Write-Host "IP is set" -ForegroundColor DarkGreen
}

if ($json.keep_tailscale_on -eq "" -or $json.keep_tailscale_on -ne "$false" -and $json.keep_tailscale_on -ne "$true" -or $reconfigure.Contains("Keep-Tailscale-On") -or $json.first_run)
{
    $json.keep_tailscale_on = "$false"
    Write-Warning "It is not specified whether you should stay connected to tailnet when this program is closed, to continue with the default setting 'no', press Enter"

    do
    {
        $read = Read-Host "Do you want to leave tailscale running after the program is closed? Y/N"

        if ($read.ToUpper() -eq "Y")
        {
            $json.keep_tailscale_on = "$true"
        }
        elseif ($read.ToUpper() -eq "N" -or $read.ToUpper() -eq "")
        {
            $json.keep_tailscale_on = "$false";
        }
    }
    while($read.ToUpper() -ne "Y" -and $read.ToUpper() -ne "N" -and $read.ToUpper() -ne "")

    Write-Host "Action set successfuly" -ForegroundColor DarkGreen
}
else {
    Write-Host "Action is set" -ForegroundColor DarkGreen
}

$json.first_run = $false
$json | ConvertTo-Json | Out-File .\config.json
Write-Host "`nTo reconfigure these settings again, edit the file or run this script with '-reconfigure' parameter`n" -ForegroundColor DarkGray
Write-Host "----"

if ($json.is_tailscale_instaled -eq "" -or $json.is_tailscale_instaled -eq "$false")
{
    do
    {
        $read = Read-Host "Do you have tailscale installed on your system? Y/N"

        if ($read.ToUpper() -eq "Y")
        {
            $json.is_tailscale_instaled = "$true"
        }
        elseif ($read.ToUpper() -eq "N")
        {
            $json.is_tailscale_instaled = "$true";
            Write-Host "Downloading tailscale..." -ForegroundColor DarkBlue
            winget install -e --id tailscale.tailscale
        }
        $json | ConvertTo-Json | Out-File .\config.json
    }
    while($read.ToUpper() -ne "Y" -and $read.ToUpper() -ne "N")
}

if ($json.is_udp_port_open -eq "" -or $json.is_udp_port_open -eq "$false")
{
    do
    {
        Write-Host "`nDo you want to open UDP port 25565? Y/N"
        Write-Host "The rule will be added to firewall EVEN when you have already opened the port." -ForegroundColor Red
        Write-Host "Because of the nature of UDP, it is not possible to determine whether the port is open or not." -ForegroundColor Red
        Write-Host "It is advised to check, before you proceed!" -ForegroundColor Red
        Write-Host "This action will not work if you have not started this script as an administrator!" -ForegroundColor Red
        $read = Read-Host

        if ($read.ToUpper() -eq "Y")
        {
            $json.is_udp_port_open = "$True";

            New-NetFirewallRule -DisplayName "SPT Fika P2P" -Direction Outbound -LocalPort 25565 -Protocol UDP -Action Allow
            New-NetFirewallRule -DisplayName "SPT Fika P2P" -Direction Inbound -LocalPort 25565 -Protocol UDP -Action Allow
            Write-Host "Ports have been opened`n" -ForegroundColor DarkGreen
        }
        elseif ($read.ToUpper() -eq "N")
        {
            $json.is_udp_port_open = "$True";
        }
        $json | ConvertTo-Json | Out-File .\config.json
    }
    while($read.ToUpper() -ne "Y" -and $read.ToUpper() -ne "N")
}

Write-Host "Checking for running tailscale service..." -ForegroundColor DarkBlue
if ($null -ne (Get-Process tailscale-ipn -ErrorAction SilentlyContinue))
{
    Write-Host "Tailscale is running`n" -ForegroundColor DarkGreen
}
else 
{
    Write-Error "Tailscale is not running"
    Write-Host "Manualy start tailscale..." -ForegroundColor DarkBlue
    while($null -eq (Get-Process tailscale-ipn -ErrorAction SilentlyContinue)){}
    Write-Host "Tailscale is running" -ForegroundColor DarkGreen
}
Write-Host "Checking for updates..." -ForegroundColor DarkBlue
winget update -e --id tailscale.tailscale 
Write-Host "`nLogging in..." -ForegroundColor DarkBlue

if($json.auth_key -eq "")
{
    do
    {
        Write-Host "Do you want to continue with auth key login method? Y/N"
        Write-Host "When using this method, you won't need an account."
        $read = Read-Host
    
        if ($read.ToUpper() -eq "Y")
        {
            Write-Host "`nPaste your auth key here:"
            $read_key = Read-Host

            tailscale logout
            $output = tailscale up --auth-key $read_key
            if ($LASTEXITCODE -eq 0)
            {
                Write-Host "Key set successfuly" -ForegroundColor DarkGreen
                $json.auth_key = $read_key;
            }
            else
            {
                Write-Error "Auth key could not be verified. If you see this message, tailscale is now unusable, to fix this issue: restart tailscale GUI client, run this script again."
                Write-Host "Manualy exit tailscale..." -ForegroundColor DarkBlue 
                while($null -ne (Get-Process tailscale-ipn -ErrorAction SilentlyContinue)){}
                Write-Host "Tailscale exited succefuly`n" -ForegroundColor DarkGreen

                Write-Host "Manualy start tailscale..." -ForegroundColor DarkBlue 
                while($null -eq (Get-Process tailscale-ipn -ErrorAction SilentlyContinue)){}
                Write-Host "Tailscale started succefuly`n" -ForegroundColor DarkGreen

                Write-Host "Setting auth key value in config file to default..." -ForegroundColor DarkBlue 
                $json.auth_key = ""
                $json | ConvertTo-Json | Out-File .\config.json
                Write-Host "Value set succefuly`n" -ForegroundColor DarkGreen
                Write-Host "Run the script again using .\run" -ForegroundColor Yellow
                exit
            }
        }
        elseif ($read.ToUpper() -eq "N")
        {
            Write-Host "Continuing with account method for login..." -ForegroundColor DarkBlue
            $json.auth_key = "$false";
            tailscale up
            Write-Host "Tailscale service is now running." -ForegroundColor DarkGreen
        }
    }
    while($read.ToUpper() -ne "Y" -and $read.ToUpper() -ne "N")
}
elseif ($json.auth_key -eq "$false")
{
    tailscale up
    Write-Host "Tailscale service is now running." -ForegroundColor DarkGreen

    if ($json.show_guide -eq "" -or $json.show_guide -eq "$true")
    {
        do
        {
            Write-Host "`nTutorial on how to connect to another user will shortly open in you browser."
            $read = Read-Host "Do you want to see this tutorial the next time you run this script? Y/N"

            if ($read.ToUpper() -eq "Y")
            {
                $json.show_guide = "$True";
            }
            elseif ($read.ToUpper() -eq "N")
            {
                $json.show_guide = "$False";
            }
        }
        while($read.ToUpper() -ne "Y" -and $read.ToUpper() -ne "N")
    }
}
else
{
    Write-Host "Checking auth key..." -ForegroundColor DarkBlue
    tailscale logout
    $output = tailscale up --auth-key $json.auth_key
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "Auth key validated successfully" -ForegroundColor DarkGreen
    }
    else
    {
        Write-Error "Auth key could not be verified. If you see this message, tailscale is now unusable, to fix this issue: restart tailscale GUI client, run this script again."
        Write-Host "Manualy exit tailscale" -ForegroundColor DarkBlue 
        while($null -ne (Get-Process tailscale-ipn -ErrorAction SilentlyContinue)){}
        Write-Host "Tailscale exited succefuly`n" -ForegroundColor DarkGreen

        Write-Host "Manualy start tailscale..." -ForegroundColor DarkBlue 
        while($null -eq (Get-Process tailscale-ipn -ErrorAction SilentlyContinue)){}
        Write-Host "Tailscale started succefuly`n" -ForegroundColor DarkGreen

        Write-Host "Setting auth key value in config file to default..." -ForegroundColor DarkBlue 
        $json.auth_key = ""
        $json | ConvertTo-Json | Out-File .\config.json
        Write-Host "Value set succefuly`n" -ForegroundColor DarkGreen
        Write-Host "Run the script again using .\run" -ForegroundColor Yellow
        Read-Host "Press Enter to exit..."
        exit
    }
}
$json | ConvertTo-Json | Out-File .\config.json

# Fika plugin existence check
Write-Host "`nChecking for existence of fika plugin in /BepInEx/plugins..." -ForegroundColor DarkBlue
$fika_plugin_path = $json.spt_launcher_path + "/BepInEx/plugins/Fika.Core.dll"
if (Test-Path -Path $fika_plugin_path)
{
    Write-Host "Fika plugin recognized`n" -ForegroundColor DarkGreen
}
else {
    Write-Warning "Fika plugin not found, download it from release section from this github repository and paste it into /BepInEx/plugins"
    Write-Host "`nhttps://github.com/project-fika/Fika-Plugin`n"
    Write-Host "Waiting for plugin to be recognized..." -ForegroundColor DarkBlue
    while (!(Test-Path -Path $fika_plugin_path)){}
    Write-Host "Fika plugin recognized`n" -ForegroundColor DarkGreen 
}

# Corter-ModSync plugin existence check
Write-Host "Checking for existence of Corter-ModSync plugin in /BepInEx/plugins..." -ForegroundColor DarkBlue
$modsync_plugin_path = $json.spt_launcher_path + "/BepInEx/plugins/Corter-ModSync.dll"
if (Test-Path -Path $modsync_plugin_path)
{
    Write-Host "Corter-ModSync plugin recognized" -ForegroundColor DarkGreen
}
else {
    Write-Warning "Corter-ModSync plugin not found, download it from release section from this github repository and paste it into /BepInEx/plugins"
    Write-Host "`nhttps://github.com/c-orter/modsync`n"
    Write-Host "Waiting for plugin to be recognized..." -ForegroundColor DarkBlue
    while (!(Test-Path -Path $modsync_plugin_path)){}
    Write-Host "Corter-ModSync plugin recognized" -ForegroundColor DarkGreen 
}

Write-Host "`nSetting IP address of server inside SPT Launcher config..." -ForegroundColor DarkBlue
$spt_config_path = $json.spt_launcher_path + "/user/launcher/config.json"
# check spt path
if (-not (Get-Content -Raw $spt_config_path -ErrorAction SilentlyContinue))
{
    Write-Host "The path to the SPT launcher config file is invalid, launching spt.lancher to generate the file..." -ForegroundColor DarkBlue
    $working_dir = Get-Location
    Set-Location -Path $json.spt_launcher_path
    .\SPT.Launcher.exe
    Set-Location -Path $working_dir
    Write-Host "Waiting for 5 seconds" -ForegroundColor DarkBlue
    for ($x -eq 0;$x -le 5;$x++)
    {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host "`nClosing the launcher..." -ForegroundColor DarkBlue
    Stop-Process -Name "SPT.Launcher"
}
# check ip address
if (Test-NetConnection $json.spt_server_ip -Port 6969 -ErrorAction SilentlyContinue -InformationLevel Quiet)
{
    Write-Host "Server IP is reachable.`n" -ForegroundColor DarkGreen
}
else 
{
    Write-Error "Server IP is not reachable. You may have configured the IP wrong, try running the script with an parameter: -reconfigure Spt-Server-Ip"
    Read-Host "Press Enter to exit..."
    exit
}

$spt_json = Get-Content -Raw $spt_config_path | ConvertFrom-Json
$spt_json.Server.Url = "http://" + $json.spt_server_ip + ":6969"
$spt_json.IsDevMode = $true
$spt_json | ConvertTo-Json | Out-File $spt_config_path

Write-Host "Starting SPT Launcher..." -ForegroundColor DarkBlue
$working_dir = Get-Location
Set-Location -Path $json.spt_launcher_path
.\SPT.Launcher.exe
Set-Location -Path $working_dir
if ($null -ne (Get-Process SPT.Launcher -ErrorAction SilentlyContinue))
{
    Write-Host "SPT Launcher is running`n" -ForegroundColor DarkGreen
}
else 
{
    Write-Error "SPT Launcher is not running`n"
}

Write-Host "To close this script, press enter..." 


if ($json.keep_tailscale_on -ne "$true")
{
    Write-Host "You will be disconnected from tailscale" -ForegroundColor DarkGray
    Read-Host
    tailscale down
}
else 
{
    Write-Host "You won't be disconnected from tailscale" -ForegroundColor DarkGray
    Read-Host
}
exit




