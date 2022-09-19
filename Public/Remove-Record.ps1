function Remove-Record {
    <#
		.SYNOPSIS
			Removes an AirTable table record.
	
		.EXAMPLE
			PS> Find-Record -BaseName foo -Table bar -Name 'old' | Remove-Record

			Removes any records in the 'bar' table with a field Name value of 'old'.
		
		.PARAMETER InputObject
			A pscustomobject value representing the record to remove. This is typically used via the pipeline.
	
	#>
    [OutputType('void')]
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'ByObject')]
        [ValidateNotNullOrEmpty()]
        [pscustomobject]$InputObject,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ApiKey
    )


    $ErrorActionPreference = 'Stop'

    $uri = BuildUriString -BaseId $InputObject.'Base ID' -Table $InputObject.Table -RecordId $InputObject.'Record ID'

    $invParams = @{
        Uri    = $uri
        Method = 'DELETE'
    }
    if ($PSBoundParameters.ContainsKey('ApiKey')) {
        $invParams.ApiKey = $ApiKey
    }

    $targetMsg = "AirTable Record ID [$($InputObject.'Record ID')] in table [$($InputObject.Table)]"
    $actionMsg = 'Remove'
    if ($PSCmdlet.ShouldProcess($targetMsg, $actionMsg)) {
        InvokeAirTableApiCall @invParams
    }
}