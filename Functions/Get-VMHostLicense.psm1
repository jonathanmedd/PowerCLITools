function Get-VMHostLicense {
<#
    .SYNOPSIS
    Function to retrieve the license of a vSphere host.
    
    .DESCRIPTION
    Function to retrieve the license of a vSphere host.
    
    .PARAMETER VMHost
    A vSphere ESXi Host object

    .INPUTS
    System.Management.Automation.PSObject.

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    PS> Get-VMHostLicense -VMHost ESXi01,ESXi02
    
    .EXAMPLE
    PS> Get-VMHost ESXi01,ESXi02 | Get-VMHostLicense
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost    
    )    

    begin {
    
        $LicenseObject = @()
        
        # --- Check for the VIProperty OSName which should be loaded from the vSphere Tools Module Initialise script
        try {
            Get-VIProperty -Name VMHostID | Out-Null
        }        
        catch [Exception] {
            throw "Required VIProperty VMHostID does not exist"
        } 
               
        # --- Get access to the vCenter License Manager
        $ServiceInstance = Get-View ServiceInstance
        $LicenseManager = Get-View $ServiceInstance.Content.LicenseManager
        $LicenseAssignmentManager = Get-View $LicenseManager.LicenseAssignmentManager
    }
    
    process {
    

        try {
            
            foreach ($ESXiHost in $VMHost){
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
                
                # --- Query the License Manager with VMHostID
                $VMHostID = $ESXiHost.VMHostID
                $License = $LicenseAssignmentManager.QueryAssignedLicenses($VMHostID)
                $License = $License.GetValue(0)
                
                $Object = [pscustomobject]@{                        
                    
                    VMHost = $ESXiHost.Name
                    Key = $License.AssignedLicense.LicenseKey
                    Type = $License.AssignedLicense.Name
                    Total = $License.AssignedLicense.Total
                    Used = $License.AssignedLicense.Used
                }
                
                $LicenseObject += $Object
            }
        }
        catch [Exception]{
        
            throw "Unable to retrieve License"
        }    
    }
    end {
        Write-Output $LicenseObject
    }
}