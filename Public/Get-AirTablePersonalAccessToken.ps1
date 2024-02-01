function Get-AirTablePersonalAccessToken {
    <#
		.SYNOPSIS
			Queries the configuration to return the personal access token set earlier via the Save-AirTablePersonalAccessToken command.
	
		.EXAMPLE
			PS> Get-AirTablePersonalAccessToken

			This example pulls the API personal access token from the configuration file.

	
	#>
    [CmdletBinding()]
    param
    ()
	
    $ErrorActionPreference = 'Stop'

    function decrypt([string]$TextToDecrypt) {
        $secure = ConvertTo-SecureString $TextToDecrypt
        $hook = New-Object system.Management.Automation.PSCredential("test", $secure)
        $plain = $hook.GetNetworkCredential().Password
        return $plain
    }

    try {
        if (-not ($encApiPat = (Get-PSAirTableConfiguration).Application.PersonalAccessToken)) {
            throw 'No API personal access token found in configuration.'
        } else {
            $atPat = decrypt $encApiPat
            $script:AirTablePat = $atPat
            $script:AirTablePat
        }
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}