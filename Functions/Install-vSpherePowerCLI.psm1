function Install-vSpherePowerCLI {
<#
    .SYNOPSIS
    Function to install VMware vSphere PowerCLI.
    
    .DESCRIPTION
    Function to install VMware vSphere PowerCLI.
    
    .PARAMETER MediaPath
    Path to the vCenter vSphere PowerCLI Media executable

    .PARAMETER InstallDir
    Custom directory to install vCenter vSphere PowerCLI
    
    .PARAMETER Quiet
    Do not display a dialogue box during install

    .INPUTS
    IO.FileInfo.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> Install-vSpherePowerCLI -MediaPath "E:\Software\VMware-PowerCLI-5.1.0-793510.exe" -InstallDir "E:\VMware\PowerCLI"
#>
[CmdletBinding()]

    Param
    (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [IO.FileInfo]$MediaPath,
     
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [IO.FileInfo]$InstallDir,
    
    [parameter(Mandatory=$false)]
    [Switch]$Quiet
    
    )
    
    
    try {    
        
        # --- Test the path to $MediaPath exists 
        if (!($MediaPath.Exists)) {throw "Cannot continue. vSphere PowerCLI Media does not exist"}
        
        # --- Test the install path does noy contain a space. PowerCLI cmd line install does not support custom paths with spaces
        if ($PSBoundParameters.ContainsKey('InstallDir')) {
            if ($InstallDir -match "\s"){
                throw "PowerCLI cmd line install does not support custom paths with spaces"
            }        
        }
       
        
                
        # --- Build the arguments for the installer
        if ($PSBoundParameters.ContainsKey('Quiet')) {        
            $Arguments = " /s /v`" /qn "
        }
        else {
            $Arguments = " /s /v`" /qr "        
        }
        
        if ($PSBoundParameters.ContainsKey('InstallDir')) {
            $Arguments += "INSTALLDIR=\`"$($InstallDir)\`" "
        }
        
        $Arguments += "`""          

        Write-Verbose "Arguments for the install are: $arguments"
        
        # --- Start the install        
        Start-Process $MediaPath $Arguments -Wait
    }
    
    catch [Exception] {
        throw "Could not install vSphere PowerCLI"
    }    
}