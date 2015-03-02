function Set-VMHostDumpCollector {
<#
    .SYNOPSIS
    Function to set the Dump Collector config of a VMHost.
    
    .DESCRIPTION
    Function to set the Dump Collector config of a VMHost.
    
    .PARAMETER VMHost
    VMHost to configure Dump Collector settings for.

    .PARAMETER HostVNic
    VNic to use

    .PARAMETER NetworkServerIP
    IP of the Dump Collector

    .PARAMETER NetworkServerPort
    Port of the Dump Collector

    .INPUTS
    String.
    System.Management.Automation.PSObject.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> Set-VMHostDumpCollector -HostVNic "vmk0" -NetworkServerIP "192.168.0.100" -NetworkServerPort 6500 -VMHost ESXi01
    
    .EXAMPLE
    PS> Get-VMHost ESXi01,ESXi02 | Set-VMHostDumpCollector -HostVNic "vmk0" -NetworkServerIP "192.168.0.100" -NetworkServerPort 6500
#>
[CmdletBinding()]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost,

    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$HostVNic,

    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$NetworkServerIP,

    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [int]$NetworkServerPort
    )    

    begin {
    

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
            

                # --- Set the Dump Collector config via ESXCli
                Write-Verbose "Setting Dump Collector config for $ESXiHost"
                $ESXCli = Get-EsxCli -VMHost $ESXiHost                

                $ESXCli.System.Coredump.Network.Set($null, $HostVNic, $NetworkServerIP, $NetworkServerPort) | Out-Null
                $ESXCli.System.Coredump.Network.Set($true) | Out-Null

                Write-Verbose "Successfully Set Dump Collector config for $ESXiHost"
            }
            catch [Exception]{
        
                throw "Unable to set Dump Collector config"
            }
        }   
    }
    end {
        
    }
}