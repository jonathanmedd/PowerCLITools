function Get-VMHostAlarm {
<#
    .SYNOPSIS
    Function to retrieve the alarm(s) of a vSphere host.
    
    .DESCRIPTION
    Function to retrieve the alarm(s) of a vSphere host.
    
    .PARAMETER VMHost
    A vSphere ESXi Host object

    .INPUTS
    System.Management.Automation.PSObject.

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    PS> Get-VMHostAlarm -VMHost ESXi01,ESXi02
    
    .EXAMPLE
    PS> Get-VMHost ESXi01,ESXi02 | Get-VMHostAlarm
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost    
    )    

    begin {

        $AlarmObject = @()
        
         
        # --- Check for the VIProperty ShortID which should be loaded from the vSphere Tools Module Initialise script
        try {
            Get-VIProperty -Name ShortID | Out-Null
        }        
        catch [Exception] {
            throw "Required VIProperty ShortID does not exist"
        }

        $AlarmDefinitions = Get-AlarmDefinition
    }
    
    process {
    

        try {

            
            foreach ($ESXiHost in $VMHost){
                if ($ESXiHost.GetType().Name -eq "string"){
                
                    try {
						$ESXiHost = Get-VMHost $ESXiHost -ErrorAction Stop
					}
					catch [Exception]{
						Write-Warning "VMHost $ESXiHost does not exist"
					}
                }
                
                elseif ($ESXiHost -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]){
					Write-Warning "You did not pass a string or a VMHost object"
					Return
				}
                
                # --- If Alarms exist retrieve their properties
                if ($HostTriggeredAlarms = $ESXiHost.ExtensionData.TriggeredAlarmState){

                    foreach ($HostTriggeredAlarm in $HostTriggeredAlarms){

                       $Object = [pscustomobject]@{                        
                    
                            VMHost = $ESXiHost.Name
                            Alarm = ($AlarmDefinitions | Where-Object {$_.ShortID -eq ($HostTriggeredAlarm.alarm.value)}).Name
                            Status = (Get-Culture).TextInfo.ToTitleCase($HostTriggeredAlarm.OverallStatus.ToString())
                            Time = $HostTriggeredAlarm.Time.ToLocalTime()
                        }
                        
                        $AlarmObject += $Object
		            }
                }
            }
        }
        catch [Exception]{
        
            throw "Unable to retrieve Alarm"
        }    
    }
    end {
        Write-Output $AlarmObject
    }
}