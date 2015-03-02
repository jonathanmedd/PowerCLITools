function Get-VMHostSyslogConfig {
<#
    .SYNOPSIS
    Function to get the Syslog config of a VMHost.
    
    .DESCRIPTION
    Function to get the Syslog config of a VMHost. Added extra functionality that Get-VMHostSysLogServer is missing
    Get-VMHostSysLogServer does not (currently) include the ability to query an ESXi host if it is configured with multiple Syslogservers
    
    .PARAMETER VMHost
    VMHost to configure Syslog settings for.

    .INPUTS
    String.
    System.Management.Automation.PSObject.

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    PS> Get-VMHostSyslogConfig -VMHost ESXi01
    
    .EXAMPLE
    PS> Get-VMHost ESXi01,ESXi02 | Get-VMHostSyslogConfig
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost
    )    

    begin {
    
        $SyslogServerObject = @()       
    }
    
    process {    
        
        foreach ($ESXiHost in $VMHost){

            try {           

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

               # --- Get Advanced Configuration value Syslog.global.logHost

               $SyslogGlobalLoghost = Get-AdvancedSetting -Entity $ESXiHost -Name 'Syslog.global.logHost'

               $Object = [pscustomobject]@{                        
                
                    VMHost = $ESXiHost
                    SyslogServer = $SyslogGlobalLoghost.Value
                }
                
                $SyslogServerObject += $Object

            }
            catch [Exception]{
        
                throw "Unable to get Syslog config"
            }
        }  
    }
    end {
        
        Write-Output $SyslogServerObject
    }
}