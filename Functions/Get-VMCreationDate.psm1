function Get-VMCreationDate {
<#
    .SYNOPSIS
    Function to retrieve the creation date of a VM.
    
    .DESCRIPTION
    Function to retrieve the creation date of a VM.
    
    .PARAMETER Name
    A vSphere VM object

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject.
    VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl.

    .EXAMPLE
    PS> Get-VMCreationDate -Name VM01,VM02
    
    .EXAMPLE
    PS> Get-VM VM01,VM02 | Get-VMCreationDate
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$Name   
    )    

    begin {
    
        $CreationDateObject = @()
        
        
        # --- Check for the VIProperty OSName which should be loaded from the vSphere Tools Module Initialise script
        try {
            Get-VIProperty -Name OSName | Out-Null
        }        
        catch [Exception] {
            throw "Required VIProperty OSName does not exist"
        }
        
        # --- Check for the VIProperty DNSName which should be loaded from the vSphere Tools Module Initialise script
        try {
            Get-VIProperty -Name DNSName | Out-Null
        }        
        catch [Exception] {
            throw "Required VIProperty DNSName does not exist"
        } 
        
        # --- Set the VI Events to search for
        $EventTypes = "VMBeingDeployedEvent","VmCreatedEvent","VmRegisteredEvent","VmClonedEvent"
    }
    
    process {
    

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
                
                # --- Query vCenter Events for VM creation time
                $CreationEvent = $VM | Get-VIEvent -Types Info -MaxSamples ([int]::MaxValue) | Where-Object {$EventTypes -contains $_.GetType().Name}
                
                if ($CreationEvent){
                    
                    Write-Verbose "Found a vCenter event"
                    $VMCreationDate = $CreationEvent.CreatedTime.ToShortDateString()
                }
                else {
                    # --- If a Windows VM query Active Directory for the computer account creation date
                    if ($VM.OSName -like '*windows*'){
                        
                        if ($DNSName = $VM.DNSName){
                            
                            
                            $DNSNameSplit = $DNSName.Split(".")
                            
                            if (($DNSNameSplit | Measure-Object).Count -eq 1){
                            
                                $SearchString = $DNSNameSplit[0]
                            }
                            else {
                            
                                $SearchString = $DNSNameSplit[1] + "\" + $DNSNameSplit[0]
                            }
                            
                            Write-Verbose "Checking AD..."
                            
                            try {
                                if ($ADComputerAccount = Search-ADAccountName -AccountName $SearchString -objectCategory 'Computer'){
                                
                                    $VMCreationDate = $ADComputerAccount.Properties.whencreated | ForEach-Object {$_.ToShortDateString()}
                                }
                            }
                            catch [Exception]{
                                Write-Warning "Unable to search AD for creation date of $SearchString"
                                 $VMCreationDate = "Unknown"
                            }
                        }
                        
                        else {
                        
                            $VMCreationDate = "Unknown"
                        }                     
                    }
                    else {
                        $VMCreationDate = "Unknown"
                    }           
                }
                
                $Object = [pscustomobject]@{                        
                    
                    VM = $VM.Name
                    CreationDate = $VMCreationDate
                }
                
                $CreationDateObject += $Object
            }
        }
        catch [Exception]{
        
            throw "Unable to retrieve Creation Date"
        }    
    }
    end {
        Write-Output $CreationDateObject
    }
}