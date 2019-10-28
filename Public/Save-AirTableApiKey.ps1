function Save-AirTableApiKey {
    <#
		.SYNOPSIS
			Saves the API key to the configuration file obtained from your AirTable account at https://airtable.com/account.
	
		.EXAMPLE
			PS> Save-AirTableApiKey -ApiKey foobar

			Saves the value 'foobar' in the configuration APIKey value.
	
	#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiKey
    )

    function encrypt([string]$TextToEncrypt) {
        $secure = ConvertTo-SecureString $TextToEncrypt -AsPlainText -Force
        $encrypted = $secure | ConvertFrom-SecureString
        return $encrypted
    }
	
    $config = Get-PSAirTableConfiguration
    $config.Application.ApiKey = encrypt($ApiKey)
    $config | ConvertTo-Json | Set-Content -Path "$WorkingDir\Configuration.json"
}