function GetBaseIdentityType {
    <#
		.SYNOPSIS
			A helper function to figure out if the base identity is the name of the base or the ID
	
		.EXAMPLE
			PS> GetBaseIdentityType -Identity 'appXXXXXXXXXXXXXX'
	
	#>
    [OutputType('string')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('BaseName', 'BaseId')]
        [string]$Identity
    )

    $ErrorActionPreference = 'Stop'

    if ($Identity -match '^app[a-zA-Z0-9]{14}$') {
        'ID'
    } else {
        'Name'
    }
}