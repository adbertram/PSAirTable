function InvokeAirTableApiCall {
    <#
		.SYNOPSIS
			A private function that crafts the REST call to AirTable.
	
		.EXAMPLE
			PS> InvokeAirTableApiCall -Uri 'https://api.airtable.com/v0/Fruit' -HttpBody @{ filterByFormula = "{Name}='Apple'" }

			Queries the AirTable URI and passes the HTTP body to the API using the GET method.

		.EXAMPLE
			PS> InvokeAirTableApiCall -Uri 'https://api.airtable.com/v0/Fruit' -HttpBody @{ filterByFormula = "{Name}='Apple'" } -Method POST

			Queries the AirTable URI and passes the HTTP body to the API using the POST method.

     		.EXAMPLE
			PS> InvokeAirTableApiCall -Uri 'https://api.airtable.com/v0/Fruit' -HttpBody @{ filterByFormula = "{Name}='Apple'" } -Method POST -CharSet 'utf-8'

			Queries the AirTable URI and passes the HTTP body to the API using the POST method with charset 'utf-8'

		.PARAMETER Uri
			A string value representing the API endpoint URI.

		.PARAMETER HttpBody
			A hashtable value representing the HTTP body to send to the API.

		.PARAMETER Method
			A string value representing the HTTP verb (method) to send to the API. This defaults to using GET.
   
   		.PARAMETER CharSet
     			A string value representing charset like utf-8, which is used for the http-request.
			Possible charsets:
			https://www.iana.org/assignments/character-sets/character-sets.xhtml
	
	#>
    [OutputType('pscustomobject')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [hashtable]$HttpBody,

 	[Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$CharSet,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Method = 'GET',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$PersonalAccessToken = (Get-AirTablePersonalAccessToken)
    )

    $ErrorActionPreference = 'Stop'

    try {
        $headers = @{
            'Authorization' = "Bearer $PersonalAccessToken"
        }
		
        $invRestParams = @{
            Method             = $Method
            Headers            = $headers
            Uri                = $Uri
            StatusCodeVariable = 'irmStatus'
        }

        switch ($Method) {
            'GET' {
                if ($PSBoundParameters.ContainsKey('HttpBody')) {
                    $invRestParams.Body = $HttpBody
                }
                break
            }
            { $_ -in 'PATCH', 'POST', 'DELETE' } {
	    	if($CharSet){
                	$invRestParams.ContentType = 'application/json; charset=' + $CharSet
		 }
   		else{
     			$invRestParams.ContentType = 'application/json'
		}
                if ($PSBoundParameters.ContainsKey('HttpBody')) {
                    $invRestParams.Body = (ConvertTo-Json $HttpBody)
                }
                break
            }
            default {
                throw "Unrecognized input: [$_]"
            }
        }

        try {
            $response = Invoke-RestMethod @invRestParams
            if ($irmStatus -ne 200) {
                throw $response
            }
        } catch {
            $err = ($_.errordetails.message | ConvertFrom-Json).error
            throw "The Airtable API returned a [$($err.type)] error with message: [$($err.message)]"
        }
		
        if ('records' -in $response.PSObject.Properties.Name) {
            $baseId = $Uri.split('/')[4]
            $table = $Uri.split('/')[5]
            $response.records.foreach({
                    $output = $_.fields
                    $output | Add-Member -MemberType NoteProperty -Name 'Record ID' -Value $_.id
                    $output | Add-Member -MemberType NoteProperty -Name 'Base ID' -Value $baseId
                    $output | Add-Member -MemberType NoteProperty -Name 'Table' -Value $table -PassThru
                })
			
            while ('offset' -in $response.PSObject.Properties.Name) {
                $invParams = [hashtable]$PSBoundParameters
                if ($invParams['HttpBody'] -and $invParams['HttpBody'].ContainsKey('offset')) {
                    $invParams['HttpBody'].offset = $response.offset
                } else {
                    $invParams['HttpBody'] = $HttpBody + @{ offset = $response.offset }
                }
				
                InvokeAirTableApiCall @invParams | Tee-Object -Variable response
            }
        } elseif ('fields' -in $response.PSObject.Properties.Name) {
            $baseId = $Uri.split('/')[4]
            $table = $Uri.split('/')[5]
            $output = $response.fields
            $output | Add-Member -MemberType NoteProperty -Name 'Record ID' -Value $response.id
            $output | Add-Member -MemberType NoteProperty -Name 'Base ID' -Value $baseId
            $output | Add-Member -MemberType NoteProperty -Name 'Table' -Value $table -PassThru
        }
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}
