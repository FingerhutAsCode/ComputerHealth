[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [String] $TestNotification = $null
)

$ConfigPath = "config.xml"
$ToastNotificationScriptPath = ".\ToastNotificationScript\New-ToastNotification.ps1"
$NotificationPath = ".\Notifications"

if ($null -ne $TestNotification) {
    switch($TestNotification) {
        'RecentReboot' {
            & $ToastNotificationScriptPath -config "$NotificationPath\RebootRequired.xml"
        }
    }
}

# Load XML
$XML = [xml](Get-Content -Path $ConfigPath -Encoding UTF8)

$RestartWindow = ($XML.Configuration.Global.Option | Where-Object { $_.Name -eq "RestartWindow" }).Value

$RecentRebootXMLConfig = $XML.Configuration.Feature | Where-Object { $_.Name -eq "RecentReboot" }
if ($RecentRebootXMLConfig.Enabled) {
    $RecentRebootConfig = [PSCustomObject]@{
        Enabled       = $RecentRebootXMLConfig.Enabled
        MaxDaysUptime = ($RecentRebootXMLConfig.option | Where-Object { $_.Name -eq "MaxDaysUptime" }).Value
    }
}

$RecentADConnectionXMLConfig = $XML.Configuration.Feature | Where-Object { $_.Name -eq "RecentADConnection" }
if ($RecentADConnectionXMLConfig.Enabled) {
    $RecentADConnectionConfig = [PSCustomObject]@{
        Enabled                = $RecentADConnectionXMLConfig.Enabled
        MaxDaysSinceConnection = ($RecentADConnectionXMLConfig.option | Where-Object { $_.Name -eq "MaxDaysSinceConnection" }).Value
    }
}

function Test-RecentReboot() {
    $ComputerLastBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $CurrentDateTime = Get-Date
    $DaysSinceLastBoot = (New-TimeSpan -Start $ComputerLastBootTime -End $CurrentDateTime).Days
    if ($DaysSinceLastBoot -lt $RecentRebootConfig.MaxDaysUptime) {
        return $true
    }
    else {
        return $false
    }
}

if (-not(Test-RecentReboot)) {
    & $ToastNotificationScriptPath -config "$NotificationPath\RebootRequired.xml"
}

function Test-RecentADConnection() {
    $LastGPOUpdate = [datetime]::FromFileTime(([Int64] ((Get-ItemProperty -Path "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Extension-List\{00000000-0000-0000-0000-000000000000}").startTimeHi) -shl 32) -bor ((Get-ItemProperty -Path "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Extension-List\{00000000-0000-0000-0000-000000000000}").startTimeLo))
    $CurrentDateTime = Get-Date
    $DaysSinceLastGPOUpdate = (New-TimeSpan -Start $LastGPOUpdate -End $CurrentDateTime).Days
    if ($DaysSinceLastGPOUpdate -lt $RecentADConnectionConfig.MaxDaysSinceConnection) {
        return $true
    }
    else {
        return $false
    }
}

if (-not(Test-RecentADConnection)) {
    & ".\Toast-Notification\New-ToastNotification.ps1" -config ".\Toast-Notification\config-toast-rebootpending.xml"
}