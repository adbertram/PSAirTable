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