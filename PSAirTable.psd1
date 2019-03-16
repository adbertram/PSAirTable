@{
	RootModule        = 'PSAirTable.psm1'
	ModuleVersion     = '1.0.1'
	GUID              = 'd7226345-7229-44df-a16d-60c1bb301b94'
	Author            = 'Adam Bertram'
	CompanyName       = 'TechSnips, LLC'
	Copyright         = '(c) 2018 TechSnips, LLC. All rights reserved.'
	Description       = 'PSAirTable is a module that allows you to interact with the AirTable services in a number of different ways with PowerShell.'
	RequiredModules   = @()
	FunctionsToExport = @('Get-AirTableApiKey', 'Save-AirTableApiKey', 'Get-PSAirTableConfiguration', 'Find-Record', 'Update-Record', 'New-Record', 'Remove-Record')
	VariablesToExport = @()
	AliasesToExport   = @()
	PrivateData       = @{
		PSData = @{
			Tags       = @('AirTable', 'REST')
			ProjectUri = 'https://github.com/adbertram/PSAirTable'
		}
	}
}