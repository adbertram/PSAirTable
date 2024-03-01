$ErrorActionPreference = 'Stop'

try {
    ## Don't upload the build scripts and appveyor.yml to PowerShell Gallery
    ## Remove all of the files/folders to exclude out of the main folder
    $excludeFromPublish = @(
        'PSAirTable\\buildscripts'
        'PSAirTable\\appveyor\.yml'
        'PSAirTable\\\.git'
        'PSAirTable\\\.nuspec'
        'PSAirTable\\README\.md'
    )
    $exclude = $excludeFromPublish -join '|'
    Get-ChildItem -Path $env:APPVEYOR_BUILD_FOLDER -Recurse | Where-Object { $_.FullName -match $exclude } | Remove-Item -Force -Recurse

    ## Publish module to PowerShell Gallery
    $publishParams = @{
        Path        = $env:APPVEYOR_BUILD_FOLDER
        NuGetApiKey = $env:nuget_apikey
        Repository  = 'PSGallery'
        Force       = $true
        Confirm     = $false
    }
    Publish-Module @publishParams

} catch {
    Write-Error -Message $_.Exception.Message
    $host.SetShouldExit($LastExitCode)
}