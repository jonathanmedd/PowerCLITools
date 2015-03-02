# --- Check for IE Publisher Certificate Revocation and disable if necessary.
# --- Speeds up PowerCLI startup, see http://blogs.vmware.com/vipowershell/2010/01/troubleshooting-slow-startup-with-powercli-40-u1.html
$CertificateRevocation = (Get-ItemProperty -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing" -Name State).State
if ($CertificateRevocation -ne 146944){
    
    try {
        Set-ItemProperty -Path "HKCU:Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing" -Name State -Value 146944
    }
    catch [Exception] {
    
        Write-Warning "Unable to set Registry Value HKCU\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing\State to disable Publisher Certificate Revocation"
    }
}


# --- Load PSSnapins
Confirm-PSSnapin VMware.VimAutomation.Core


# --- Create VIProperties

# --- AlarmDefinition
New-VIProperty -Name "ShortID" -ObjectType AlarmDefinition -Value {
    param($AlarmDefinition)
    $AlarmDefinition.ID -creplace 'Alarm-', '' 
} -Force | Out-Null


# --- Cluster
New-VIProperty -Name "TotalCPUGhz" -ObjectType Cluster -Value {
    param($Cluster)
    [math]::Round($Cluster.ExtensionData.Summary.TotalCPU * 0.001,2)
} -BasedOnExtensionProperty Summary.TotalCPU -Force | Out-Null

New-VIProperty -Name "TotalRAMGB" -ObjectType Cluster -Value {
    param($Cluster)
    [math]::Round($Cluster.ExtensionData.Summary.TotalMemory / 1GB,2)
} -BasedOnExtensionProperty Summary.TotalMemory -Force | Out-Null

New-VIProperty -Name "TotalAllocatedvCPUs" -ObjectType Cluster -Value {
    param($Cluster)
    $TotalvCPU = 0
    $Cluster | Get-VM | ForEach-Object {$TotalvCPU += $_.NumCPU}
    $TotalvCPU
} -Force -WarningAction:SilentlyContinue | Out-Null

New-VIProperty -Name "TotalAllocatedvRAMGB" -ObjectType Cluster -Value {
    param($Cluster)
    $TotalvRAMGB = 0
    $Cluster | Get-VM | ForEach-Object {$TotalvRAMGB += $_.MemoryGB}
    $TotalvRAMGB
} -Force -WarningAction:SilentlyContinue | Out-Null

New-VIProperty -Name "NumberOfHosts" -ObjectType Cluster -Value {
    param($Cluster)
    @($Cluster.Extensiondata.Host).Count
} -BasedOnExtensionProperty Host -Force | Out-Null

New-VIProperty -Name "HostFailureImpact" -ObjectType Cluster -Value {
    param($Cluster)
    [math]::Round((1 / (@($Cluster.Extensiondata.Host).Count)) * 100,2)
} -BasedOnExtensionProperty Host -Force | Out-Null


# --- Datastore
New-VIProperty -Name "ProvisionedGB" -ObjectType Datastore -Value {
		param($DataStore)

		[Math]::Round(($DataStore.ExtensionData.Summary.Capacity - $DataStore.ExtensionData.Summary.FreeSpace + $DataStore.ExtensionData.Summary.Uncommitted)/1GB,0)
} -BasedONextensionProperty 'Summary' -Force | Out-Null


# --- VirtualMachine
New-VIProperty -Name "OSName" -ObjectType VirtualMachine -ValueFromExtensionProperty Config.GuestFullName -Force | Out-Null
New-VIProperty -Name "DNSName" -ObjectType VirtualMachine -ValueFromExtensionProperty Guest.Hostname -Force | Out-Null

New-VIProperty -Name 'BlueFolderPath' -ObjectType VirtualMachine -Value {
    param($vm)

    function Get-ParentName{
        param($object)

        if($object.Folder){
            $blue = Get-ParentName $object.Folder
            $name = $object.Folder.Name
        }
        elseif($object.Parent -and $object.Parent.GetType().Name -like "Folder*"){
            $blue = Get-ParentName $object.Parent
            $name = $object.Parent.Name
        }
        elseif($object.ParentFolder){
            $blue = Get-ParentName $object.ParentFolder
            $name = $object.ParentFolder.Name
        }
        if("vm","Datacenters" -notcontains $name){
            $blue + "\" + $name
        }
        else{
            $blue
        }
    }

    (Get-ParentName $vm).Remove(0,1)
} -Force | Out-Null



# --- VMHost
New-VIProperty -Name "VMHostID" -ObjectType VMHost -Value {
    param($VMHost)
    $VMHost.ExtensionData.Config.Host.Value
} -BasedOnExtensionProperty Config.Host -Force | Out-Null


New-VIProperty -Name "NumberOfVMs" -ObjectType VMHost -Value {
    param($VMHost)
    ($VMHost | Get-VM | Measure-Object).Count 
} -Force | Out-Null

New-VIProperty -Name "CPUPercent" -ObjectType VMHost -Value {
    param($VMHost)
    ($VMHost.CpuUsageMhz / $VMHost.CpuTotalMhz) * 100 -as [int]
} -Force | Out-Null

New-VIProperty -Name "MemoryPercent" -ObjectType VMHost -Value {
    param($VMHost)
    ($VMHost.MemoryUsageGB / $VMHost.MemoryTotalGB) * 100 -as [int]
} -Force | Out-Null