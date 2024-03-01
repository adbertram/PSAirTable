function Get-PSAirTableConfiguration {
    <#
		.SYNOPSIS
			Queries the configuration stored as a JSON file in the module directory and returns as a PowerShell object.
	
		.EXAMPLE
			PS> Get-PSAirTableConfiguration

			Queries the configuration JSON file and returns values.
	
	#>
    [OutputType('string')]
    [CmdletBinding()]
    param
    ()

    $ErrorActionPreference = 'Stop'

    try {
        if (-not (Test-Path -Path $script:configFilePath)) {
            throw "The required configuration.json file could not be found in the required location of [$($script:configFilePath)]."
        }

        Get-Content -Path $script:configFilePath -Raw | ConvertFrom-Json
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}