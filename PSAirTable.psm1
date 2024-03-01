#Requires -Version 5

Set-StrictMode -Version Latest

$WorkingDir = $MyInvocation.MyCommand.Path | Split-Path -Parent
$EndPointUri = 'https://api.airtable.com/v0'

$configFileParentFolder = if ($PSVersionTable.PSVersion -lt [Version]"6.0" -or $IsWindows) {
    $env:APPDATA
} elseif ($IsMacOS) {
    "$HOME/Library/Application Support"
} elseif ($IsLinux) {
    "$HOME/.config"
}
$configFileParentFolder = Join-Path -Path $configFileParentFolder -ChildPath 'PSAirTable'

$script:configFilePath = Join-Path -Path $configFileParentFolder -ChildPath "configuration.json"
if (-not (Test-Path $script:configFilePath)) {
    $null = New-Item -ItemType File -Path $script:configFilePath -Force
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'configuration.json') -Destination $script:configFilePath
}

# Get public and private function definition files.
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files.
foreach ($import in @($Public + $Private)) {
    try {
        Write-Verbose "Importing $($import.FullName)"
        . $import.FullName
    } catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

foreach ($file in $Public) {
    Export-ModuleMember -Function $file.BaseName
}