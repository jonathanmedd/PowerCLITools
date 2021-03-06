function Remove-vCenterLicense {
<#
    .SYNOPSIS
    Function to remove a license from vCenter.
    
    .DESCRIPTION
    Function to remove a license from vCenter.
    
    .PARAMETER LicenseKey
    License key of the license to remove from vCenter

    .INPUTS
    String.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> Remove-vCenterLicense -LicenseKey "F2JQE-5SE2W-3KSN7-0SMH6-93NSH","SMNW9-0276S-02MJS-HFNDJ-WKDM4"
    
    .EXAMPLE
    PS> "F2JQE-5SE2W-3KSN7-0SMH6-93NSH" | Remove-vCenterLicense
#>
[CmdletBinding()]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$LicenseKey   
    )    

    begin {
     
               
        # --- Get access to the vCenter License Manager
        $ServiceInstance = Get-View ServiceInstance
        $LicenseManager = Get-View $ServiceInstance.Content.LicenseManager
    }
    
    process {
    

        try {
            
            foreach ($Key in $LicenseKey){
                
                # --- Test the License exists in vCenter and has 0 in use
                if ($License = Get-vCenterLicense -LicenseKey $Key){
                
                    if ($License.Used -ne 0){
                    
                        Write-Warning "License with key $Key is still assigned so unable to remove"
                        Continue
                    }
                
                }
                else {
                
                    Write-Warning "Unable to find License with key $Key"
                    Continue
                }
                
                # --- Remove the License from vCenter
                $LicenseManager.RemoveLicense("$Key")

            }
        }
        catch [Exception]{
        
            throw "Unable to remove License $Key"
        }    
    }
    end {
        
    }
}