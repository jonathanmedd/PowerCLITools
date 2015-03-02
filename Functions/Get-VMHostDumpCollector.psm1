function Get-VMHostDumpCollector {
<#
    .SYNOPSIS
    Function to get the Dump Collector config of a VMHost.
    
    .DESCRIPTION
    Function to get the Dump Collector config of a VMHost.
    
    .PARAMETER VMHost
    VMHost to configure Dump Collector settings for.

    .INPUTS
    String.
    System.Management.Automation.PSObject.

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    PS> Get-VMHostDumpCollector -VMHost ESXi01
    
    .EXAMPLE
    PS> Get-VMHost ESXi01,ESXi02 | Get-VMHostDumpCollector
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost
    )    

    begin {
    

        $DumpCollectorObject = @()       
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

               # --- Get Dump Collector Config via ESXCli

               $ESXCli = Get-EsxCli -VMHost $ESXiHost

               $DumpCollector = $ESXCli.System.Coredump.Network.Get()

               $Object = [pscustomobject]@{                        
                
                    VMHost = $ESXiHost
                    HostVNic = $DumpCollector.HostVNic
                    NetworkServerIP = $DumpCollector.NetworkServerIP
                    NetworkServerPort = $DumpCollector.NetworkServerPort
                    Enabled = $DumpCollector.Enabled
                }
                
                $DumpCollectorObject += $Object

            }
            catch [Exception]{
        
                throw "Unable to get Dump Collector config"
            }
        }  
    }
    end {
        
        Write-Output $DumpCollectorObject
    }
}