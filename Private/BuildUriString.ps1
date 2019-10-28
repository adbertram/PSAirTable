function BuildUriString {
    <#
		.SYNOPSIS
			A pricate helper function to craft the URI necessary to pass to the AirTable API.
	
		.EXAMPLE
			PS> BuildUriString -BaseId XXXXXXXXX -Table Fruit

			Returns the URI. This is typically used by Find-Record and New-Record.
		
		.EXAMPLE
			PS> BuildUriString -BaseId XXXXXXXXX -Table Fruit -RecordId recXXXXXX

			Returns the URI. This is typically used by Update-Record.

		.PARAMETER BaseId
			The ID of the AirTable base that is defined in the module configuration.
		
		.PARAMETER Table
			A string value representing the AirTable table containing the records to query.

		.PARAMETER RecordId
			A string value representing the record ID that will be appended to the end of the URI.
	
	#>
    [OutputType('string')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('BaseName', 'BaseId')]
        [string]$BaseIdentity,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Table,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$RecordId
    )

    $ErrorActionPreference = 'Stop'

    $baseId = GetBaseId -Identity $BaseIdentity

    $uriParts = @($EndpointUri, $baseId, $Table)
    if ($PSBoundParameters.ContainsKey('RecordId')) {
        $uriParts += $RecordId
    }
    $uriParts -join '/'
}