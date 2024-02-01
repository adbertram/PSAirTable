# PSAirTable
PSAirTable is a PowerShell module for interacting with the AirTable database services.

## How to Use

Once this module has been imported:

1. Create an AirTable account [here](https://airtable.com/signup).

2. Generate your AirTable API key [here](https://airtable.com/account).

6. Run `Save-AirTablePersonalAccessToken -PersonalAccessToken XXXXXXXX` to save your API personal access token encrypted in the Configuration.json file.

3. Create one or more AirTable [bases](https://support.airtable.com/hc/en-us/articles/202576419-Introduction-to-Airtable-bases).

4. Add any base IDs you'd like to query with PSAirTable in the module's Configuration.json file.

7. Run any of the functions in the module to interact with your AirTable records! Be sure to check out the built-in help for each command if you get stuck.
