function New-VMFromSnapshot {
<#
    .SYNOPSIS
    Function to create a clone from a snapshot of a VM.
    
    .DESCRIPTION
    Function to create a clone from a snapshot of a VM.
    
    .PARAMETER SourceVM
    VM to clone from.

    .PARAMETER CloneName
    Name of the clone to create

    .PARAMETER SnapshotName
    Name of the snapshot to clone from

    .PARAMETER CurrentSnapshot
    Use the current snapshot instead of a named snapshot

    .PARAMETER Cluster
    Name of the cluster to place the clone in

    .PARAMETER Datastore
    Name of the datastore to place the clone in

    .PARAMETER VMFolder
    Name of the Virtual Machine folder to put the VM in

    .PARAMETER LinkedClone
    Create a linked clone from the snapshot, rather than a full clone

    .INPUTS
    String.
    System.Management.Automation.PSObject.

    .OUTPUTS
    VMware.Vim.ManagedObjectReference.

    .EXAMPLE
    PS> New-VMFromSnapshot -SourceVM VM01 -CloneName "Clone01" -Cluster "Test Cluster" -Datastore "Datastore01"

    .EXAMPLE
    PS> New-VMFromSnapshot -SourceVM VM01 -CloneName "Clone01" -SnapshotName "Testing" -Cluster "Test Cluster" -Datastore "Datastore01" -VMFolder "Test Clones" -LinkedClone
#>
[CmdletBinding(DefaultParameterSetName=”Current Snapshot”)][OutputType('VMware.Vim.ManagedObjectReference')]

    Param
    (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject]$SourceVM,
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$CloneName,

    [parameter(Mandatory=$true,ParameterSetName="Named Snapshot")]
    [ValidateNotNullOrEmpty()]
    [String]$SnapshotName,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Cluster,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Datastore,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$VMFolder,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Switch]$LinkedClone
    )
    
        

    # --- Retrieve snapshot tree using try / catch since if it doesn't exist, an exception is generated
    function Test-SnapshotExists ($SnapshotQuery) {

        try {
            Write-Verbose "Testing $SnapshotQuery....`n"
            $TestSnapshot = Invoke-Expression $SnapshotQuery
            Write-Output $TestSnapshot
        }

        catch [Exception]{

            $TestSnapshot = $false
            Write-Output $TestSnapshot
        }
    }

    try {            

        if ($SourceVM.GetType().Name -eq "string"){
                
            try {
				$SourceVM = Get-VM $SourceVM -ErrorAction Stop
			}
			catch [Exception]{
				Write-Warning "VM $SourceVM does not exist"
			}
        }
                
        elseif ($SourceVM -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]){
			Write-Warning "You did not pass a string or a VM object"
			Return
		}                
                
        # --- Set values for the Clone Spec
        if ($PSBoundParameters.ContainsKey('Cluster')){
            
            $DefaultClusterResourcePoolMoRef = (Get-Cluster $Cluster | Get-ResourcePool "Resources").ExtensionData.MoRef
        }

        if ($PSBoundParameters.ContainsKey('Datastore')){

            $DatastoreMoRef = (Get-Datastore $Datastore).ExtensionData.MoRef
        }

        if ($PSBoundParameters.ContainsKey('LinkedClone')){

            $CloneType = "createNewChildDiskBacking"
        }
        else {

            $CloneType = "moveAllDiskBackingsAndDisallowSharing"
        }

        if ($PSBoundParameters.ContainsKey('VMFolder')){

            try {

                $Folder = Get-Folder $VMFolder -Type VM -ErrorAction Stop
                $CloneFolder = $Folder.ExtensionData.MoRef
            }
            catch [Exception] {

                Write-Warning "VM Folder $VMFolder does not exist, using existing folder instead"
                $CloneFolder = $SourceVM.ExtensionData.Parent
            }
        }
        else {

            $CloneFolder = $SourceVM.ExtensionData.Parent
        }                

        # --- Create CloneSpec and initiate Clone Task
        switch ($PsCmdlet.ParameterSetName) 
        { 
            "Named Snapshot"  {
                    
                $Snapshots = @()
                $SnapshotQuery = '$SourceVM.ExtensionData.Snapshot.RootSnapshotList[0]'

                while ($Snapshot = Test-SnapshotExists -SnapshotQuery $SnapshotQuery){

                    $SnapshotQuery += '.ChildSnapshotList[0]'
                    $Snapshots += $Snapshot
                }                        

                $CloneSpec = New-Object Vmware.Vim.VirtualMachineCloneSpec
                $CloneSpec.Snapshot = ($Snapshots | Where-Object {$_.Name -eq $SnapshotName}).Snapshot
                $CloneSpec.Location = New-Object Vmware.Vim.VirtualMachineRelocateSpec
                $CloneSpec.Location.Pool = $DefaultClusterResourcePoolMoRef
                $CloneSpec.Location.Datastore = $DatastoreMoRef
                $CloneSpec.Location.DiskMoveType = [Vmware.Vim.VirtualMachineRelocateDiskMoveOptions]::$CloneType

                $SourceVM.ExtensionData.CloneVM_Task($CloneFolder, $CloneName, $CloneSpec)
            }

            "Current Snapshot"  {

                $CloneSpec = New-Object Vmware.Vim.VirtualMachineCloneSpec
                $CloneSpec.Snapshot = $SourceVM.ExtensionData.Snapshot.CurrentSnapshot
                $CloneSpec.Location = New-Object Vmware.Vim.VirtualMachineRelocateSpec
                $CloneSpec.Location.Pool = $DefaultClusterResourcePoolMoRef
                $CloneSpec.Location.Datastore = $DatastoreMoRef
                $CloneSpec.Location.DiskMoveType = [Vmware.Vim.VirtualMachineRelocateDiskMoveOptions]::$CloneType

                $SourceVM.ExtensionData.CloneVM_Task($CloneFolder, $CloneName, $CloneSpec)                    
            }
        }
    }
    catch [Exception]{
        
        throw "Unable to deploy new VM from snapshot"
    }
}