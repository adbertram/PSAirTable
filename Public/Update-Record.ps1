function Update-Record {
    <#
		.SYNOPSIS
			Updated an AirTable table record field value(s).
	
		.EXAMPLE
			PS> Find-Record -BaseName foo -Table bar -Name 'old' | Update-Record -Fields { 'Name' = 'new' }

			Updates any records in the 'bar' table with a field Name value of 'old' to 'new'.

		.EXAMPLE
			PS> Update-Record -BaseName foo -Table bar -Id recXXXXXXXXX -Fields { 'Name' = 'new' }

			Updates any records in the 'bar' table with a field Name value of 'old' to 'new'.
		
		.PARAMETER InputObject
			A pscustomobject value representing the record to update. This is typically used via the pipeline.

		.PARAMETER Id
			A string value representing the record ID of the record to update.

		.PARAMETER BaseName
			A string value representing the AirTable base that contains the table to query.

		.PARAMETER Table
			A string value representing the AirTable table containing the records to query.

		.PARAMETER Fields
			A hashtable value representing all of the record's fields to update. Each key in the hashtable is the
			field name and each corresponding value is the value to update the field to.
	
	#>
    [OutputType('void')]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Default')]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByObject')]
        [ValidateNotNullOrEmpty()]
        [pscustomobject]$InputObject,

        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^rec')]
        [string]$Id,

        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [Alias('BaseName', 'BaseId')]
        [string]$BaseIdentity,

        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [string]$Table,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Fields,

        [switch]$PassThru,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$PersonalAccessToken
    )

    begin {
        $ErrorActionPreference = 'Stop'
    }
	
    process {
        if ($PSCmdlet.ParameterSetName -eq 'ById') {
            $InputObject = [pscustomobject]@{
                'Base ID' = $BaseIdentity
                'Table' = $Table
                'Record ID' = $Id
            }
        }
        $uri = BuildUriString -BaseId $InputObject.'Base ID' -Table $InputObject.Table -RecordId $InputObject.'Record ID'

        $invParams = @{
            Uri      = $uri
            Method   = 'PATCH'
            HttpBody = @{
	    	    'fields' = $Fields
		        'typecast' = $True
	        }
        }
        if ($PSBoundParameters.ContainsKey('PersonalAccessToken')) {
            $invParams.PersonalAccessToken = $PersonalAccessToken
        }

        $targetMsg = "AirTable Record ID [$($InputObject.'Record ID')] in table [$($InputObject.Table)]"
        $actionMsg = "Update fields [$($Fields.Keys -join ',')] to [$($Fields.Values -join ',')]"
        if ($PSCmdlet.ShouldProcess($targetMsg, $actionMsg)) {
            if ($PassThru.IsPresent){
                InvokeAirTableApiCall @invParams
            } else {
                InvokeAirTableApiCall @invParams | Out-Null
            }
        }
    }
}
