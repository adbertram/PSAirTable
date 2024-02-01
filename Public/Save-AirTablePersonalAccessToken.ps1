function Save-AirTablePersonalAccessToken {
    <#
		.SYNOPSIS
			Saves the API personal access token to the configuration file obtained from your AirTable account at https://airtable.com/create/tokens.
	
		.EXAMPLE
			PS> Save-AirTablePersonalAccessToken -PersonalAccessToken foobar

			Saves the value 'foobar' in the configuration PersonalAccessToken value.
	
	#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PersonalAccessToken
    )

    function encrypt([string]$TextToEncrypt) {
        $secure = ConvertTo-SecureString $TextToEncrypt -AsPlainText -Force
        $encrypted = $secure | ConvertFrom-SecureString
        return $encrypted
    }
	
    $config = Get-PSAirTableConfiguration
    $config.Application.PersonalAccessToken = encrypt($PersonalAccessToken)
    $config | ConvertTo-Json | Set-Content -Path "$WorkingDir\Configuration.json"
}