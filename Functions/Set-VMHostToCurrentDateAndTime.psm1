function Set-VMHostToCurrentDateandTime {
<#
    .SYNOPSIS
    Function to set the Date and Time of a VMHost to current.
    
    .DESCRIPTION
    Function to set the Date and Time of a VMHost to current.
    
    .PARAMETER VMHost
    VMHost to configure Date and Time settings for.

    .INPUTS
    String.
    System.Management.Automation.PSObject.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> Set-VMHostToCurrentDateandTime -VMHost ESXi01
    
    .EXAMPLE
    PS> Get-VMHost ESXi01,ESXi02 | Set-VMHostToCurrentDateandTime

#>
[CmdletBinding()]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost
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
            

                # --- Set the Date and Time to the current Date and Time
                Write-Verbose "Setting the Date and Time to the current Date and Time for $ESXiHost"
                $Time = Get-Date
                $DateTimeSystem = $ESXiHost | ForEach-Object { Get-View $_.ExtensionData.ConfigManager.DateTimeSystem }
                $DateTimeSystem.UpdateDateTime((Get-Date($Time.ToUniversalTime()) -Format u))
                Write-Verbose "Successfully set the Date and Time to the current Date and Time for $ESXiHost"
            }
            catch [Exception]{
        
                throw "Unable to set current Date and Time"
            }
        }   
    }
    end {
        
    }
}