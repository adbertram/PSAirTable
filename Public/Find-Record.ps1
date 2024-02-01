function Find-Record {
    <#
		.SYNOPSIS
			Queries an AirTable table for one or more records.
	
		.EXAMPLE
			PS> Find-Record -BaseName foo -Table bar

			Returns all records in the bar table within the foo base.

		.EXAMPLE
			PS> Find-Record -BaseName foo -Table bar -FilterFormula '{Name}="adam"'

			Returns all records in the bar table within the foo base that have a Name value of 'adam'.

		.PARAMETER BaseName
			A string value representing the AirTable base that contains the table to query.

		.PARAMETER Table
			A string value representing the AirTable table containing the records to query.

		.PARAMETER FilterFormula
			A string value representing an AirTable-specific filter to limit the number of records returned. For 
			full explanation of this query language, refer to 
			https://support.airtable.com/hc/en-us/articles/203255215-Formula-field-reference.

		.PARAMETER View
			An optional string parameter representing a table view to limit results to.
	
	#>
    [OutputType('pscustomobject')]
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
        [string]$FilterFormula,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$View,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]$MaxRecords = 100,

        [Parameter()]
        [ValidateSet('asc', 'desc')]
        [string]$SortDirection,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$SortField,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$PersonalAccessToken
		
    )

    $ErrorActionPreference = 'Stop'

    $baseId = GetBaseId -Identity $BaseIdentity

    $uri = BuildUriString -BaseId $baseId -Table $Table
    $invParams = @{
        Uri = $Uri
    }
    if ($PSBoundParameters.ContainsKey('PersonalAccessToken')) {
        $invParams.PersonalAccessToken = $PersonalAccessToken
    }
    
    $httpBody = @{ }
    if ($PSBoundParameters.ContainsKey('FilterFormula')) {
        $httpBody['filterByFormula'] = $FilterFormula
    }
    if ($PSBoundParameters.ContainsKey('View')) {
        $httpBody['view'] = $View
    }
    if ($PSBoundParameters.ContainsKey('MaxRecords')) {
        $httpBody['maxRecords'] = $MaxRecords
    }
    if ($PSBoundParameters.ContainsKey('SortField')) {
        $httpBody['sort[0][field]'] = $SortField
        if ($PSBoundParameters.ContainsKey('SortDirection')) {
            $httpBody['sort[0][direction]'] = $SortDirection
        }
    }
    if ($httpBody.Keys -gt 0) {
        $invParams.HttpBody = $httpBody
    }
    InvokeAirTableApiCall @invParams
	
}