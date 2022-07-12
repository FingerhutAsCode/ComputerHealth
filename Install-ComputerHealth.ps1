<#
.DESCRIPTION
Install the Computer Health necessary files and setup schedule task

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [String] $InstallPath = "$env:ProgramFiles\FingerhutAsCode",
    [Parameter(Mandatory = $false)]
    [String] $ScheduledTaskName = "FingerhutAsCode Computer Health"
)

# Test for Install Path and if it does not exist, create it
if (-not(Test-Path $InstallPath)) {
    $InstallPathRoot = $InstallPath | Split-Path -Parent
    $InstallPathFolderName = $InstallPath | Split-Path -Leaf
    New-Item -Path $InstallPathRoot -Name $InstallPathFolderName -ItemType "Directory"
}

Copy-Item -Path "Computer Health" -Destination $InstallPath -Recurse -Force