Function Get-CurrentVIServer
{
	<#
		.SYNOPSIS
		Function to return the currently connected VI server object.

		.DESCRIPTION
		If there are no currently connected VI servers, an error is raised.
		If there are more than 1 currently connected VI servers, an error is raised.

		.EXAMPLE
		PS> Get-CurrentVIServer

	#>
	[CmdletBinding()]
	Param()

	try
	{
		# --- Get the global variable
		$ConnectedVIServers = @($Global:DefaultVIServers | Where-Object {$_.IsConnected})
		Switch ($ConnectedVIServers.Count)
		{
			0 {throw "There are no currently connected VI Servers"}
			1 {return $ConnectedVIServers[0]}
			Default {throw "There are multiple currently connected VI Servers"}
		}
	}
	catch
	{
		throw "Failed to Get Current VI Server"
	}
}
