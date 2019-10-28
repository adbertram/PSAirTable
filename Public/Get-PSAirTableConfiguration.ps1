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
        $configJsonPath = "$WorkingDir\Configuration.json"
        if (-not (Test-Path -Path $configJsonPath)) {
            throw 'The required Configuration.json file could not be found.'
        }

        Get-Content -Path $configJsonPath -Raw | ConvertFrom-Json
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}