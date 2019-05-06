Set-StrictMode -Version Latest

$WorkingDir = $MyInvocation.MyCommand.Path | Split-Path -Parent
$EndPointUri = 'https://api.airtable.com/v0'

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
		} elseif (Get-Variable -Name AirTableApiKey -Scope Script -ErrorAction 'Ignore') {
			$script:AirTableApiKey
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

function Get-PSAirTableConfiguration {
	<#
		.SYNOPSIS
			Queries the configuration stored as a JSON file in the module directory and returns as a PowerShell object.
	
		.EXAMPLE
			PS> Get-PSAirTableConfiguration

			Queries the configuration JSON file and returns values.
	
	#>
	[OutputType('string')]
	[CmdletBinding()]
	param
	()

	$ErrorActionPreference = 'Stop'

	try {
		$configJsonPath = "$WorkingDir\Configuration.json"
		if (-not (Test-Path -Path $configJsonPath)) {
			throw 'The required Configuration.json file could not be found.'
		}

		Get-Content -Path $configJsonPath -Raw | ConvertFrom-Json
	} catch {
		$PSCmdlet.ThrowTerminatingError($_)
	}
}

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
		[ValidateSet('asc','desc')]
		[string]$SortDirection,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$SortField
		
	)

	$ErrorActionPreference = 'Stop'

	$baseId = GetBaseId -Identity $BaseIdentity

	$uri = BuildUriString -BaseId $baseId -Table $Table
	$invParams = @{
		Uri = $Uri
	}
	$httpBody = @{}
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

		[switch]$PassThru
	)

	begin {
		$ErrorActionPreference = 'Stop'
	}
	
	process {
		if ($PSCmdlet.ParameterSetName -eq 'ById') {
			$filterFormula = 'RECORD_ID()="{0}"' -f $Id
			$InputObject = Find-Record -BaseName $BaseIdentity -Table $Table -FilterFormula $filterFormula
		} else {

		}
		$uri = BuildUriString -BaseId $InputObject.'Base ID' -Table $InputObject.Table -RecordId $InputObject.'Record ID'

		$invParams = @{
			Uri      = $uri
			Method   = 'PATCH'
			HttpBody = @{ 'fields' = $Fields }
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
		[pscustomobject]$InputObject
	)


	$ErrorActionPreference = 'Stop'

	$uri = BuildUriString -BaseId $InputObject.'Base ID' -Table $InputObject.Table -RecordId $InputObject.'Record ID'

	$invParams = @{
		Uri    = $uri
		Method = 'DELETE'
	}

	$targetMsg = "AirTable Record ID [$($InputObject.'Record ID')] in table [$($InputObject.Table)]"
	$actionMsg = 'Remove'
	if ($PSCmdlet.ShouldProcess($targetMsg, $actionMsg)) {
		InvokeAirTableApiCall @invParams
	}
}

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

		.PARAMETER Uri
			A string value representing the API endpoint URI.

		.PARAMETER HttpBody
			A hashtable value representing the HTTP body to send to the API.

		.PARAMETER Method
			A string value representing the HTTP verb (method) to send to the API. This defaults to using GET.
	
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
		[string]$Method = 'GET',

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$ApiKey = (Get-AirTableApiKey)
	)

	$ErrorActionPreference = 'Stop'

	try {
		$headers = @{
			'Authorization' = "Bearer $ApiKey"
		}
		
		$invRestParams = @{
			Method  = $Method
			Headers = $headers
			Uri     = $Uri
		}

		switch ($Method) {
			'GET' {
				if ($PSBoundParameters.ContainsKey('HttpBody')) {
					$invRestParams.Body = $HttpBody
				}
				break
			}
			{ $_ -in 'PATCH', 'POST', 'DELETE' } {
				$invRestParams.ContentType = 'application/json'
				if ($PSBoundParameters.ContainsKey('HttpBody')) {
					$invRestParams.Body = (ConvertTo-Json $HttpBody)
				}
				break
			}
			default {
				throw "Unrecognized input: [$_]"
			}
		}

		$response = Invoke-RestMethod @invRestParams
		
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
					$invParams['HttpBody'] = $HttpBody + @{ offset = $response.offset  }
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

function GetBaseId {
	<#
		.SYNOPSIS
			A helper function to query the configuration with a base name and return it's ID.
	
		.EXAMPLE
			PS> GetBaseId -Identity foo

			Looks at the module configuration file for a base name defined as 'foo' and returns the ID associated with it.
	
	#>
	[OutputType('string')]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Identity
	)

	$ErrorActionPreference = 'Stop'

	$baseIdtype = GetBaseIdentityType -Identity $Identity
	if ($baseIdtype -eq 'Name') {
		$bases = (Get-PSAirTableConfiguration).Bases
		if (-not ($base = @($bases).where({ $_.Name -eq $Identity }))) {
			throw "The base name [$($Identity)] could not be found. Ensure it exists by running (Get-PSAirTableConfiguration).Bases"
		}
		$base.id
	} else {
		$Identity
	}
}

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