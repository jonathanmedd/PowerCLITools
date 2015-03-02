function Set-VMHostiSCSIBinding {
<#
.SYNOPSIS
Function to set the iSCSI Binding of a VMHost.    
.DESCRIPTION
Function to set the iSCSI Binding of a VMHost.
.PARAMETER VMHost
VMHost to configure iSCSI Binding for.
.PARAMETER HBA
HBA to use for iSCSI
.PARAMETER VMKernel
VMKernel to bind to
.PARAMETER Rescan
Perform an HBA and VMFS rescan following the changes
.INPUTS
String.
System.Management.Automation.PSObject.
.OUTPUTS
VMware.VimAutomation.ViCore.Impl.V1.EsxCli.EsxCliObjectImpl.
.EXAMPLE
Set-VMHostiSCSIBinding -HBA "vmhba32" -VMKernel "vmk1" -VMHost ESXi01 -Rescan    
.EXAMPLE
Get-VMHost ESXi01,ESXi02 | Set-VMHostiSCSIBinding -HBA "vmhba32" -VMKernel "vmk1"
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('VMware.VimAutomation.ViCore.Impl.V1.EsxCli.EsxCliObjectImpl')]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost,

    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$HBA,

    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$VMKernel,

    [parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [Switch]$Rescan
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
						$ErrorText = "VMHost $ESXiHost does not exist"
                        throw
					}
                }
                
                elseif ($ESXiHost -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]){
					$ErrorText = "You did not pass a string or a VMHost object"
					throw
				}                
            
                # --- Check for the iSCSI HBA
                try {

                    $iSCSIHBA = $ESXiHost | Get-VMHostHba -Device $HBA -Type iSCSI -ErrorAction Stop
                }
                catch [Exception]{

                    $ErrorText =  "Specified iSCSI HBA does not exist for $ESXIHost"
                    throw
                }

                # --- Check for the VMKernel
                try {

                    $VMKernelPort = $ESXiHost | Get-VMHostNetworkAdapter -Name $VMKernel -VMKernel -ErrorAction Stop
                }
                catch [Exception]{

                    $ErrorText = "Specified VMKernel does not exist for $ESXIHost"
                    throw
                }

                # --- Set the iSCSI Binding via ESXCli
                try {
                    if ($PSCmdlet.ShouldProcess($ESXiHost)){

                        Write-Verbose "Setting iSCSI Binding for $ESXiHost"
                        $ESXCli = Get-EsxCli -VMHost $ESXiHost                

                        $ESXCli.iscsi.networkportal.add($iSCSIHBA.Device, $false, $VMKernel)

                        Write-Verbose "Successfully set iSCSI Binding for $ESXiHost"

                        $iSCSIBindingOutput = $ESXCli.iscsi.networkportal.list() | Where-Object {$_.Adapter -eq $iSCSIHBA.Device -and $_.vmknic -eq $VMKernel}                        
                    }
                }
                catch [Exception]{

                    $ErrorText = "Unable to set iSCSI Binding for $ESXIHost"
                    throw
                }
                # --- Rescan HBA and VMFS if requested
                try {
                    if ($PSBoundParameters.ContainsKey('Rescan')){

                        Write-Verbose "Rescanning HBAs and VMFS for $ESXiHost"
                        $ESXiHost | Get-VMHostStorage -RescanAllHba -RescanVmfs -ErrorAction Stop | Out-Null
                    }
                }
                catch [Exception]{

                    $ErrorText = "Unable to rescan HBA and VMFS for $ESXIHost"
                    throw
                }

                # --- Output the Successful Result
                Write-Output $iSCSIBindingOutput
            }
            catch [Exception]{
                
                if ($ErrorText){
                   throw "Unable to set iSCSI Binding config for host $($ESXIHost). Error is: $($ErrorText)"
                }
                else {

                   throw "Unable to set iSCSI Binding config for host $($ESXIHost)"
                }
            }
        }   
    }
    end {
        
    }
}
