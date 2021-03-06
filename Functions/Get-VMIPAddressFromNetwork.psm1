function Get-VMIPAddressFromNetwork {
<#
    .SYNOPSIS
    Returns the IP Address for a given Network Name.

    .DESCRIPTION
    Returns the IP Address for a given Network Name.

    .PARAMETER Name
    Name of the VM.
    
    .PARAMETER NetworkName
    Name of the Network.
    
    .PARAMETER Search
    Search for the network name as a wildcard, not a literal lookup

    .INPUTS
    System.Management.Automation.PSObject.

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    PS> Get-VMIPAddressFromNetwork -Name TEST01,TEST02 -NetworkName 'Network1' | Select NetworkName,IPaddress

    .EXAMPLE
    PS> Get-VM TEST01,TEST02 | Get-VMIPAddressFromNetwork -NetworkName "Management" | Select NetworkName,IPaddress
    
    .EXAMPLE
    PS> Get-VM TEST01 | Get-VMIPAddressFromNetwork -NetworkName '*' -Search | Sort NetworkName | ft VM,NetworkName,IPAddress
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$Name,
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$NetworkName,
    
    [parameter(Mandatory=$false)]
    [Switch]$Search

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
                    
                    # --- Search for the Network Name using a wildcard
                    if ($PSBoundParameters.ContainsKey('Search')){
                        
                        $Networks = $VM.Guest.Nics | Where-Object {$_.NetworkName -like "*$NetworkName*"}
                        
                    }
                    # --- Lookup the Network Name literally
                    else {
                        $Networks = $VM.Guest.Nics | Where-Object {$_.NetworkName -eq $NetworkName}
                    }
                    
                    if ($Networks){
                        foreach ($Network in $Networks){
                              
                            $Object = [pscustomobject]@{
                                VM = $VM.Name
                                NetworkName = $Network.NetworkName
    							IPAddress = if ($Network.IPAddress){
                                    ($Network | Select-Object -ExpandProperty IPaddress) -join ","
                                    }
                                    else {
                                        $null
                                    }
                            }
							
							$MyObject += $Object
						}
                    }
                    else {
					
						$Object = [pscustomobject]@{
							VM = $VM.Name
							NetworkName = $null
							IPAddress = $null
						}
						
						$MyObject += $Object						
                    }
                }
            }

        }
        catch [Exception]{

            throw "Unable to get IP address from Network name"
        }

    }

    end {
        Write-Output $MyObject
    }
}