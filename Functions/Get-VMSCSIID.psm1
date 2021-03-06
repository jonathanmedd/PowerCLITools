function Get-VMSCSIID {
<#
    .SYNOPSIS
    Returns the SCSIID(s) for each hard disk in a VM.

    .DESCRIPTION
    Returns the SCSIID(s) for each hard disk in a VM.

    .PARAMETER Name
    Name of the VM.

    .INPUTS
    System.Management.Automation.PSObject.

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    PS> Get-VMSCSIID -Name TEST01,TEST02 | Select VM,Disk,SCSIID

    .EXAMPLE
    PS> Get-VM TEST01,TEST02 | Get-VMSCSIID | Select VM,Disk,SCSIID

#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$Name

    )

    begin {

        $MyObject = @()
    }

    process {
        try
        {
            foreach ($VM in $Name){

                if ($VM -is [String]){

                    try {
                        $VM = Get-VM -Name $VM -ErrorAction Stop
                    }
                    catch [Exception]{
                        Write-Warning "VM $VM does not exist"
                    }
                }
                elseif ($VM -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]){
                    Write-Warning "You did not pass a string or a VM object"
                    Return
                }

                if ($VM -is [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]){

                    $SCSIControllers = $VM.ExtensionData.Config.HardWare.Device | Where-Object {$_ -is [VMWare.Vim.VirtualSCSIController]}
                    $HardDisks = $VM | Get-HardDisk

                    foreach ($HardDisk in $HardDisks){

                        $UnitNumber= $HardDisk.ExtensionData.UnitNumber
                        $ControllerKey = $HardDisk.ExtensionData.ControllerKey
                        $BusNumber = ($SCSIControllers | Where-Object {$_.Key -eq $ControllerKey}).BusNumber

                        $Object = [pscustomobject]@{
                            VM = $VM.Name
							Disk = $HardDisk.Name
							ScsiLun = $BusNumber
							ScsiID = $UnitNumber
							CapacityGB = $HardDisk.CapacityGB
							Filename = $HardDisk.Filename
                        }

						
                        $MyObject += $Object
                    }
                }
            }

        }
        catch [Exception]{

            throw "Unable to get SCSI IDs"
        }

    }

    end {
        Write-Output $MyObject
    }
}