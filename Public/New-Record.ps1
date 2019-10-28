function New-Record {
    <#
		.SYNOPSIS
			Creates a new AirTable table record.
	
		.EXAMPLE
			PS> New-Record -BaseName foo -Table bar -Fields { 'Name' = 'new' }

			Creates a new record in the 'bar' table with a field Name value of 'new'.

		.PARAMETER BaseName
			A string value representing the AirTable base that contains the table to query.

		.PARAMETER Table
			A string value representing the AirTable table containing the records to query.

		.PARAMETER Fields
			A hashtable value representing all of the new record's fields. Each key in the hashtable is the
			field name and each corresponding value is the value to update the field to.
	
	#>
    [OutputType('void')]
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('BaseName', 'BaseId')]
        [string]$BaseIdentity,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Table,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Fields,

        [switch]$PassThru
    )


    $ErrorActionPreference = 'Stop'

    $baseId = GetBaseId -Identity $BaseIdentity

    $uri = BuildUriString -BaseId $baseId -Table $Table

    $invParams = @{
        Uri      = $uri
        Method   = 'POST'
        HttpBody = @{ 'fields' = $Fields }
    }

    $targetMsg = "New AirTable Record in table [$($Table)]"
    $actionMsg = "Fields [$($Fields.Keys -join ',')] to [$($Fields.Values -join ',')]"
    if ($PSCmdlet.ShouldProcess($targetMsg, $actionMsg)) {
        if ($PassThru.IsPresent){
            InvokeAirTableApiCall @invParams
        } else {
            InvokeAirTableApiCall @invParams | Out-Null
        }
    }
}