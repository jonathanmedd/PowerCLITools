Function Test-VIServerConnection
{
	<#
		.SYNOPSIS
		Function to test if a VI Server is currently connected.
		 
		.DESCRIPTION
		Returns a boolean result.
		 
		.PARAMETER
		PS> Test-VIServerConnection -VIServer 'MyTestServer56'
	#>
	[CmdletBinding()][OutputType('System.Boolean')]
	Param
	(
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[String]$VIServer
	)


	try
	{
		# --- Check if we have an active connection (use the whole string for IP addresses but only the first section for a server name)
		$isConnected = $false
		if ($Global:DefaultVIServers)
		{
			if ([Net.IPAddress]::TryParse($VIServer,[ref]([Net.IPAddress]'127.0.0.1')))
			{
				$isConnected = [Bool]($Global:DefaultVIServers | Where-Object {$_.isConnected -AND $_.Name -eq $VIServer})
			}
			else
			{
				$isConnected = [Bool]($Global:DefaultVIServers | Where-Object {$_.isConnected -AND $_.Name.Split('.')[0] -eq $VIServer.Split('.')[0]})
			}
		}

		# --- Return the result
		Write-Output $isConnected
	}
	catch [Exception]
	{
		throw "Failed to Test Connection to VI Server '$VIServer'"
	}
}
