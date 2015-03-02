function Connect-vCenter {
	<#
		.SYNOPSIS
		Connect to a vSphere vCenter.

		.DESCRIPTION
		Connect to a vSphere vCenter.

		.PARAMETER Server
		vCenter name.

		.PARAMETER Username
		User account to connect to vCenter with.

		.PARAMETER Password
		Password for user account to connect to vCenter with.

		.PARAMETER Credential
		An optional PS credential object.

		.INPUTS
		None. You cannot pipe objects to Connect-vCenter.

		.OUTPUTS
		None.

		.EXAMPLE
		C:\PS> Connect-vCenter -Server VCENTER01
	#>
	[CmdletBinding(DefaultParameterSetName='Named')]

	Param
	(
		[parameter(Mandatory=$true,Position=0)]
		[ValidateNotNullOrEmpty()]
		[String]$Server,

		[parameter(Mandatory=$false,ParameterSetName='Named')]
		[ValidateNotNullOrEmpty()]
		[String]$Username,

		[parameter(Mandatory=$false,ParameterSetName='Named')]
		[ValidateNotNullOrEmpty()]
		[String]$Password,

		[parameter(Mandatory=$false,ParameterSetName='CredentialObject')]
		[ValidateNotNullOrEmpty()]
		[Management.Automation.PSCredential]$Credential
	)

	try
	{
		# -- Check if we have an active connection (use the whole string for an IP but the first section for a server name)
		$isConnected = $false
		if ($Global:DefaultVIServers)
		{
			if ([Net.IPAddress]::TryParse($Server,[ref]([Net.IPAddress]'127.0.0.1')))
			{
				$isConnected = [Bool]($Global:DefaultVIServers | Where-Object {$_.isConnected -and $_.Name -eq $Server})
			}
			else
			{
				$isConnected = [Bool]($Global:DefaultVIServers | Where-Object {$_.isConnected -and $_.Name.Split('.')[0] -eq $Server.Split('.')[0]})
			}
		}

		# --- Connect if not already active
		if (!$isConnected)
		{
			Write-Verbose "Connecting to VIServer '$Server' ..."
			Connect-VIServer @PSBoundParameters -WarningAction SilentlyContinue
		}
		else
		{
			Write-Verbose "VI Server '$Server' is already connected"
		}
	}
	catch
	{
		throw "Failed to connect to vCenter Server '$Server'"
	}
}


function Global:Confirm-PSSnapin {
<#
    .SYNOPSIS
    Confirm whether a PSSnapin has been loaded.

    .DESCRIPTION
    Confirm whether a PSSnapin has been loaded.

    .PARAMETER PSSnapin
    Name of the PSSnapin

    .INPUTS
    None. You cannot pipe objects to Confirm-PSSnapin.

    .OUTPUTS
    None.

    .EXAMPLE
    C:\PS> Confirm-PSSnapin -PSSnapin VMware.VimAutomation.Core


#>
[CmdletBinding()]

param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$PSSnapin
)
    try {

        Write-Verbose "Confirming whether PSSnapin $PSSnapin is active...'n"
        
        if (!(Get-PSSnapin -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $PSSnapin})){
        
            if (!(Get-PSSnapin -Registered -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $PSSnapin})){

                throw "PSSnapin $($PSSnapin) is not installed...'n"
            }
            else {
                Write-Verbose "PSSnapin $PSSnapin is installed, but not active. Adding it to the current session...`n"
                Add-PSSnapin -Name $PSSnapin
            }
        }
        else {
            Write-Verbose "PSSnapin $PSSnapin is already active...`n"
        }
    }
    catch [Exception]{
        throw "Unable to confirm whether a PSSnapin has been loaded"
    }
}

function Get-StartAndFinishTime {
<#
    .SYNOPSIS 
    Get the start and finish times of a time period.

    .DESCRIPTION
    Get the start and finish times of a time period.

    .PARAMETER Today
    Time period = Today.
    
    .PARAMETER Yesterday
    Time period = Yesterday.
    
    .PARAMETER xDaysAgo
    Time period = xDaysAgo
    
    .PARAMETER PreviousFullWeek
    Time period = PreviousFullWeek, Mon - Sun
    
    .PARAMETER PreviousWeek
    Time period = PreviousWeek, Today - 7 days ago
    
    .PARAMETER xWeeksAgo
    Time period = xWeeksAgo
    
    .PARAMETER PreviousFullMonth
    Time period = PreviousFullMonth, Oct 1 - Oct 31
    
    .PARAMETER PreviousMonth
    Time period = PreviousMonth, Today - 1 Month
    
    .PARAMETER xMonthsAgo
    Time period = xMonthsAgo
    
    .PARAMETER PreviousYear
    Time period = PreviousYear, Today - 1 Year

    .INPUTS
    System.Int

    .OUTPUTS
    System.DateTime

    .EXAMPLE
    PS> Get-StartAndFinishTime -Today
    
    .EXAMPLE
    PS> Get-StartAndFinishTime -xDaysAgo 5

    .NOTES
    Version: 1.0 - First draft
    Date: 29/11/2012
    Tag: time,today,yesterday,week,month,year
#>
[CmdletBinding(DefaultParameterSetName='Today')][OutputTYpe('System.DateTime')]
    
    Param (
        [parameter(ParameterSetName='Today')]
        [Switch]$Today,
        
        [parameter(ParameterSetName='Yesterday')]
        [Switch]$Yesterday,
        
        [parameter(ParameterSetName='xDaysAgo')]
        [Int]$xDaysAgo,
        
        [parameter(ParameterSetName='PreviousFullWeek')]
        [Switch]$PreviousFullWeek,
        
        [parameter(ParameterSetName='PreviousWeek')]
        [Switch]$PreviousWeek,
        
        [parameter(ParameterSetName='xWeeksAgo')]
        [Int]$xWeeksAgo,
        
        [parameter(ParameterSetName='PreviousFullMonth')]
        [Switch]$PreviousFullMonth,
        
        [parameter(ParameterSetName='PreviousMonth')]
        [Switch]$PreviousMonth,
        
        [parameter(ParameterSetName='xMonthsAgo')]
        [Int]$xMonthsAgo,
        
        [parameter(ParameterSetName='PreviousYear')]
        [Switch]$PreviousYear
        
     )
     
     $TodayMidnight = (Get-Date -Hour 0 -Minute 0 -Second 0)
     try {
        switch ($PsCmdlet.ParameterSetName)
        {
            "Today" {
                $Start = $TodayMidnight.AddSeconds(1)
                $Finish = Get-Date
                break
            }
            
            "Yesterday" {
                $Start = $TodayMidnight.AddDays(-1).AddSeconds(1)
                $Finish = $TodayMidnight
                break
            }
            
            "xDaysAgo" {
                $Start = $TodayMidnight.AddDays(-$xDaysAgo).AddSeconds(1)
                $Finish = $TodayMidnight
                break
            }
            
            "PreviousFullWeek" {
                $EndOfWeek = $TodayMidnight.AddDays(-$TodayMidnight.DayOfWeek.value__ +1)
                $Start = $EndOfWeek.AddDays(-7).AddSeconds(1)
                $Finish = $EndOfWeek
                break
            }
            
            "PreviousWeek" {
                $Start = $TodayMidnight.AddDays(-7).AddSeconds(1)
                $Finish = $TodayMidnight
                break
            }
            
            "xWeeksAgo" {
                $Start = $TodayMidnight.AddDays(-(7 * $xWeeksAgo)).AddSeconds(1)
                $Finish = $TodayMidnight
                break
            }
            
            "PreviousFullMonth" {
                $Start = Get-Date -Day 01 -Month ($TodayMidnight.Month -1) -Year $TodayMidnight.Year -Hour 0 -Minute 0 -Second 1
                $Finish = Get-Date -Day 01 -Month ($TodayMidnight.Month) -Year $TodayMidnight.Year -Hour 0 -Minute 0 -Second 0
                break
            }
            
            "PreviousMonth" {
                $Start = $TodayMidnight.AddMonths(-1).AddSeconds(1)
                $Finish = $TodayMidnight
                break
            }
            
            "xMonthsAgo" {
                $Start = $TodayMidnight.AddMonths(-$xMonthsAgo).AddSeconds(1)
                $Finish = $TodayMidnight
                break
            }
            
            "PreviousYear" {
                $Start = $TodayMidnight.AddYears(-1).AddSeconds(1)
                $Finish = $TodayMidnight
                break
            }
            
        }
        Write-Output $Start,$Finish
}

catch [Exception]{
    throw "Unable to determine dates"
}
}