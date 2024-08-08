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
    '{"first_run":  true,"spt_launcher_path":  "","spt_server_ip":  "","keep_tailscale_on":  "False","is_tailscale_instaled":  "False","show_guide":  "True","is_udp_port_open":  "False"}' >> config.json
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
    Write-Warning "It is not specified whether tailscale should continue to run after this program is closed, the default setting is 'disabled'"

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

Write-Host "Starting tailscale service..." -ForegroundColor DarkBlue
Write-Host "Checking for updates..." -ForegroundColor DarkBlue
winget update -e --id tailscale.tailscale 
Write-Host "If you haven't logged in yet, the browser will open shortly and you will be asked to login into your tailscale account"
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
        $json | ConvertTo-Json | Out-File .\config.json
    }
    while($read.ToUpper() -ne "Y" -and $read.ToUpper() -ne "N")
}

Write-Host "`nSetting IP address of server inside SPT Launcher config..." -ForegroundColor DarkBlue
$spt_config_path = $json.spt_launcher_path + "\user\launcher\config.json"
# check spt path
if (-not (Get-Content -Raw $spt_config_path -ErrorAction SilentlyContinue))
{
    Write-Error "The path to the SPT folder is invalid. You may have configured the path wrong, try running the script with an parameter: -reconfigure Spt-Launcher-Path `n"
    exit
}
# check ip address
if (Test-NetConnection $json.spt_server_ip -Port 6969 -ErrorAction SilentlyContinue -InformationLevel Quiet)
{
    Write-Host "Server is reachable.`n" -ForegroundColor DarkGreen
}
else 
{
    Write-Error "Server is not reachable. You may have configured the IP wrong, try running the script with an parameter: -reconfigure Spt-Server-Ip"
    exit
}

$spt_json = Get-Content -Raw $spt_config_path | ConvertFrom-Json
$spt_json.Server.Url = "http://" + $json.spt_server_ip + ":6969"
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
    Write-Host "You will be logged out from tailscale" -ForegroundColor DarkGray
    Read-Host
    tailscale logout
}
else 
{
    Write-Host "You won't be logged out from tailscale" -ForegroundColor DarkGray
    Read-Host
}
exit




