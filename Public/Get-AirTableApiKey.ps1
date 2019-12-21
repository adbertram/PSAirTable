function Get-AirTableApiKey {
    <#
		.SYNOPSIS
			Queries the API key configuration to return the API key set earlier via the Save-AirTableApiKey command.
	
		.EXAMPLE
			PS> Get-AirTableApiKey

			This example pulls the API key from the configuration file.

	
	#>
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ApiKey
    )
	
    $ErrorActionPreference = 'Stop'

    function decrypt([string]$TextToDecrypt) {
        $secure = ConvertTo-SecureString $TextToDecrypt
        $hook = New-Object system.Management.Automation.PSCredential("test", $secure)
        $plain = $hook.GetNetworkCredential().Password
        return $plain
    }

    try {
        if ($PSBoundParameters.ContainsKey('ApiKey')) {
            $script:AirTableApiKey = $ApiKey
            $ApiKey
        } elseif (-not ($encApiKey = (Get-PSAirTableConfiguration).Application.ApiKey)) {
            throw 'No API key found in configuration.'
        } else {
            $atKey = decrypt $encApiKey
            $script:AirTableApiKey = $atKey
            $script:AirTableApiKey
        }
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}