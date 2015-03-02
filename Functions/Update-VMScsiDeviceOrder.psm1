function Update-VMScsiDeviceOrder {
<#
    .SYNOPSIS
    Update the Scsi Device Order of a VM disk.
    
    .DESCRIPTION
    Update the Scsi Device Order of a VM disk
    
    .PARAMETER Name
    VM to update the Scsi Device Order for.

    .PARAMETER DiskName
    Name of the disk to update

    .PARAMETER ScsiDeviceOrder
    Number from 0 - 15 of Scsi ID to update to

    .INPUTS
    String.
    System.Management.Automation.PSObject.

    .OUTPUTS
    None

    .EXAMPLE
    PS> Update-VMScsiDeviceOrder -Name VM01 -DiskName "Hard Disk 1" -ScsiDeviceOrder 2

    .EXAMPLE
    PS> Get-VM VM01,VM02 | Update-VMScsiDeviceOrder -DiskName "Hard Disk 1" -ScsiDeviceOrder 2

#>
[CmdletBinding()]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject]$Name,
    
    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$DiskName,

    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateRange(0,15)]
    [Int]$ScsiDeviceOrder
    )
    
    begin {

    }

    process{

        try {       
        
            foreach ($VM in $Name){

                if ($VM.GetType().Name -eq "string"){
                
                    try {
				        $VM = Get-VM $VM -ErrorAction Stop
			        }
			        catch [Exception]{
				        Write-Warning "VM $VM does not exist"
			        }
                }
                
                elseif ($VM -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]){
			        Write-Warning "You did not pass a string or a VM object"
			        Return
		        }            
                
                # --- Check VM is powered off
                if ($VM.PowerState -ne "PoweredOff"){

                    Write-Warning "VM $VM is not in a PoweredOff state, so it is not possible to change the SCSI device order"
                    Return
                }


                # --- Change SCSI device order

                try {
                    $Disk = Get-HardDisk -VM $VM -Name $DiskName -ErrorAction SilentlyContinue
                }
                catch [Exception]{

                    Write-Warning "Disk $DiskName does not exist for VM $VM"
                    Return
                }


                # --- Create a new VirtualMachineConfigSpec, with which to make the change to the VM's disk
                $Spec = New-Object VMware.Vim.VirtualMachineConfigSpec

                # --- Create a new VirtualDeviceConfigSpec
                $Spec.deviceChange = New-Object VMware.Vim.VirtualDeviceConfigSpec
                $Spec.deviceChange[0].operation = "edit"

                # --- Populate the "device" property with the existing info from the hard disk to change
                $Spec.deviceChange[0].device = $Disk.ExtensionData

                # --- Then, change the second part of the SCSI ID (the UnitNumber)
                $Spec.deviceChange[0].device.unitNumber = $ScsiDeviceOrder

                # --- reconfig the VM with the updated ConfigSpec (VM must be powered off)
                $VM.ExtensionData.ReconfigVM_Task($Spec) | Out-Null
            }
        }
        catch {

            throw "Unable to update Scsi Device Order of disk $Disk on VM $VM"
        }
    }

    end {

    }
}