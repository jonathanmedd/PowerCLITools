function Get-VMHostiSCSIBinding {
<#
    .SYNOPSIS
    Function to get the iSCSI Binding of a VMHost.
    
    .DESCRIPTION
    Function to get the iSCSI Binding of a VMHost.
    
    .PARAMETER VMHost
    VMHost to get iSCSI Binding for.

    .PARAMETER HBA
    HBA to use for iSCSI

    .INPUTS
    String.
    System.Management.Automation.PSObject.

    .OUTPUTS
    VMware.VimAutomation.ViCore.Impl.V1.EsxCli.EsxCliObjectImpl.

    .EXAMPLE
    PS> Get-VMHostiSCSIBinding -VMHost ESXi01 -HBA "vmhba32"
    
    .EXAMPLE
    PS> Get-VMHost ESXi01,ESXi02 | Get-VMHostiSCSIBinding -HBA "vmhba32"
#>
[CmdletBinding()][OutputType('VMware.VimAutomation.ViCore.Impl.V1.EsxCli.EsxCliObjectImpl')]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost,

    
    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$HBA
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
            
                # --- Check for the iSCSI HBA
                try {

                    $iSCSIHBA = $ESXiHost | Get-VMHostHba -Device $HBA -Type iSCSI -ErrorAction Stop
                }
                catch [Exception]{

                    Write-Warning "Specified iSCSI HBA does not exist for $ESXIHost"
                    Return
                }

                # --- Set the iSCSI Binding via ESXCli
                Write-Verbose "Getting iSCSI Binding for $ESXiHost"
                $ESXCli = Get-EsxCli -VMHost $ESXiHost                

                $ESXCli.iscsi.networkportal.list($HBA)
            }
            catch [Exception]{
        
                throw "Unable to get iSCSI Binding config"
            }
        }   
    }
    end {
        
    }
}