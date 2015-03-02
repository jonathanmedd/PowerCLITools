function Get-SnapshotCreator {
<#
    .SYNOPSIS
    Function to retrieve the creator of a vSphere Snapshot.
    
    .DESCRIPTION
    Function to retrieve the creator of a vSphere Snapshot.
    
    .PARAMETER Snapshot
    Snapshot to find the creator for

    .INPUTS
    VMware.VimAutomation.ViCore.Impl.V1.VM.SnapshotImpl.

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    PS> Get-SnapshotCreator -Snapshot (Get-VM Test01 | Get-Snapshot)
    
    .EXAMPLE
    PS> Get-VM Test01 | Get-Snapshot | Get-SnapshotCreator
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [VMware.VimAutomation.ViCore.Impl.V1.VM.SnapshotImpl[]]$Snapshot   
    )    

    begin {
    
        $SnapshotCreatorObject = @()

        $TaskMgr = Get-View TaskManager
    }
    
    process {    

        try {
            
            foreach ($Snap in $Snapshot){
         
                # --- Create a filter for the task collector
                $Filter = New-Object VMware.Vim.TaskFilterSpec
                $Filter.Time = New-Object VMware.Vim.TaskFilterSpecByTime
                $Filter.Time.BeginTime = ((($Snap.Created).AddSeconds(-20)).ToUniversalTime())
                $Filter.Time.TimeType = "startedTime"
                $Filter.Time.EndTime = ((($Snap.Created).AddSeconds(20)).ToUniversalTime())
                $Filter.State = "success"
                $Filter.Entity = New-Object VMware.Vim.TaskFilterSpecByEntity
                $Filter.Entity.recursion = "self"
                $Filter.Entity.entity = (Get-VM -Id $Snap.VMId).Extensiondata.MoRef

                # --- Get the task that matches the filter
                $TaskCollector = Get-View ($TaskMgr.CreateCollectorForTasks($Filter))

                # --- Rewind the collector view back to the top
                $TaskCollector.RewindCollector | Out-Null

                # --- Read 100 events from that point
                $Tasks = $TaskCollector.ReadNextTasks(100)

                # --- Find the creator
                if ($Tasks){
                    foreach ($Task in $Tasks){

                        $GuestName = $Snap.VM
                        $Task = $Task | Where-Object {$_.DescriptionId -eq "VirtualMachine.createSnapshot" -and $_.State -eq "success" -and $_.EntityName -eq $GuestName}

                        if ($Task){

                            $Creator = $Task.Reason.UserName
                        }
                        else {
                            $Creator = "Unable to Snapshot VM creator"
                        }
                    }
                }
                else {
                    $Creator = "Unable to find Snapshot creator"                        
                }

                # --- Remove the TaskCollector since there is a limit of 32 active collectors
                $TaskCollector.DestroyCollector()
                
                $Object = [pscustomobject]@{                        
                    
                    VM = $Snapshot.VM.Name
                    Snapshot = $Snapshot.Name
                    Creator = $Creator
                }
                
                $SnapshotCreatorObject += $Object
            }
        }
        catch [Exception]{
        
            throw "Unable to retrieve snapshot creator"
        }    
    }
    end {
        Write-Output $SnapshotCreatorObject
    }
}