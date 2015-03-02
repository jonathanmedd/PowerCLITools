function Update-VMNotesWithOwner {
<#
    .SYNOPSIS
    Function to update the Notes of a VM with its Owner.
    
    .DESCRIPTION
    Function to update the Notes of a VM with its Owner. Owner is either directly supplied or calculated from most recent vCenter event
    
    .PARAMETER Name
    A vSphere VM object

    .PARAMETER Owner
    Name of the VM Owner

    .PARAMETER ExceptionList
    List of exceptions which should be filtered out when search VM Events

    .PARAMETER WeeksAgo
    Number of Weeks to go back in time searching VM Events for

    .INPUTS
    System.String.
    System.Management.Automation.PSObject.

    .OUTPUTS
    None

    .EXAMPLE
    PS> Update-VMNotesWithOwner -Name VM01,VM02 -ExceptionList "User","vpxuser" -WeeksAgo 10

    .EXAMPLE
    PS> Update-VMNotesWithOwner -Name VM01,VM02 -Owner "Test Owner"
    
    .EXAMPLE
    PS> Get-VM VM01,VM02 | Update-VMNotesWithOwner -Name VM01,VM02 -ExceptionList "User","vpxuser" -WeeksAgo 10


#>
[CmdletBinding(DefaultParametersetName="Events")]

    Param
    (

    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$Name,

    [Parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName="Owner")]
    [ValidateNotNullOrEmpty()]
    [String]$Owner,

    [Parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName="Events")]
    [ValidateNotNullOrEmpty()]
    [String[]]$ExceptionList,

    [Parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName="Events")]
    [ValidateNotNullOrEmpty()]
    [Int]$WeeksAgo
    )    

    begin {
    

        if ($PSCmdlet.ParameterSetName -eq 'Events'){

            # --- Set Start and Finish times for VM event queries
            $Start,$Finish = Get-StartAndFinishTime -xweeksAgo $WeeksAgo
        
            # --- Always filter out blank spaces in UserNames for event queries. Add manually specified exceptions if present
            $Exceptions =  @("")
            if ($PSBoundParameters.ContainsKey('ExceptionList')){

                $Exceptions += $ExceptionList
            }
        }
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
                        Return
					}
                }
                
                elseif ($VM -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl]){
					Write-Warning "You did not pass a string or a VM object"
					Return
				}

                $ExistingNotes = $VM.Notes -split "`n" | Where-Object {$_ -notmatch "VM Owner is"}
                
                switch ($PsCmdlet.ParameterSetName) 
                { 
                    "Events"  {
                       
                        # --- Search VM Events and set VM Owner if a UserName is found
                        $UserName = Get-VM $VM | Get-VIEvent -Start $Start -Finish $Finish | Where-Object {$Exceptions -notcontains $_.UserName} | Select-Object -ExpandProperty UserName -First 1                        

                        if ($UserName){
                            
                            $Text = (@"
$($ExistingNotes | Foreach-Object {"`n$_"})
VM Owner is $($UserName)
"@).TrimStart("")

                            $VM | Set-VM -Notes $Text -Confirm:$false | Out-Null
                        }

                        break
                    } 
                    "Owner"  {
                        
                        # --- Set VM Owner based on supplied parameter
                        $Text = (@"
$($ExistingNotes | Foreach-Object {"`n$_"})
VM Owner is $($Owner)
"@).TrimStart("")

                        $VM | Set-VM -Notes $Text -Confirm:$false | Out-Null
                        break
                    } 
                }                
            }
        }
        catch [Exception]{
        
            throw "Unable to update VM Notes with Owner"
        }    
    }
    end {

    }
}