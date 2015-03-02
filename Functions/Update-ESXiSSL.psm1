function Update-ESXiSSL {
<#
    .SYNOPSIS
    Function to replace SSL certificate of an ESXi host with CA signed certificate.
    
    .DESCRIPTION
    Function to replace SSL certificate of an ESXi host with CA signed certificate.
    Uses:
    OpenSSL - http://slproweb.com/products/Win32OpenSSL.html
    certreq - built into Windows
    pscp - http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html
    
    .PARAMETER VMHost
    VMHost to configure certificate for.

    .PARAMETER OpenSSLEXE
    Path to openssl.exe

    .PARAMETER PSCPLEXE
    Path to pscp.exe

    .PARAMETER CertPath
    Path to folder to store certificates in

    .PARAMETER CAName
    Name of Certification Authority, e.g. ROOTCA01\ROOTCA01-CA

    .PARAMETER CertTemplate
    Name of the certificate template to use, e.g. CertificateTemplate:VMware-SSL

    .PARAMETER Organization
    Name of the Organization to use in the certificate

    .PARAMETER Locality
    Name of the Locality to use in the certificate

    .PARAMETER State
    Name of the State to use in the certificate

    .PARAMETER CountryName
    Name of the country to use in the certificate, e.g. US or GB

    .PARAMETER Credential
	A PS credential object.

    .INPUTS
    String.
    System.Management.Automation.PSObject.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> Update-ESXiSSL -VMHost ESXi01 -OpenSSLEXE "C:\OpenSSL\bin\openssl.exe" -PSCPEXE "C:\Putty\pscp.exe" -CertPath "C:\vCenter\Certs" -CAName "ROOTCA01\ROOTCA01-CA" -CertTemplate "CertificateTemplate:VMware-SSL" -Organization "Duff" -Locality "Springfield" -State "Springfield County" -CountryName "US" -Credential (Get-Credential)

    .EXAMPLE
    PS> Get-VMHost ESXi01 | Update-ESXiSSL -OpenSSLEXE "C:\OpenSSL\bin\openssl.exe" -PSCPEXE "C:\Putty\pscp.exe" -CertPath "C:\vCenter\Certs" -CAName "ROOTCA01\ROOTCA01-CA" -CertTemplate "CertificateTemplate:VMware-SSL" -Organization "Duff" -Locality "Springfield" -State "Springfield County" -CountryName "US" -Credential (Get-Credential)

    .NOTES
    Adapted from http://blog.netnerds.net/2013/06/update-your-esxs-ssl-certs-with-your-own-windows-domain-ca-certificates-using-powercli/

#>
[CmdletBinding()]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$VMHost,

    [Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[IO.FileInfo]$OpenSSLEXE,

    [Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[IO.FileInfo]$PSCPEXE,

    [Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[IO.DirectoryInfo]$CertPath,

    [Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[String]$CAName,

    [Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[String]$CertTemplate,

    [Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[String]$Organization,

    [Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[String]$Locality,

    [Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[String]$State,

    [Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[String]$CountryName,

    [Parameter(Mandatory=$true)]
	[ValidateNotNullOrEmpty()]
	[Management.Automation.PSCredential]$Credential
    )    

    begin {
    

        # --- Check that OpenSSL.exe is available
        if (!($OpenSSLEXE.Exists)){

            throw "Please supply the correct path to OpenSSL.exe"
        }

        # --- Check that pscp.exe is available
        if (!($PSCPEXE.Exists)){

            throw "Please supply the correct path to PSCP.exe"
        }

        # --- Create the path to store the certificates
        if (!(Test-Path -Path "$CertPath\ESXi")){

            New-Item -Path "$CertPath\ESXi" -ItemType Directory -Force
        }

        $ESXiUsername = $Credential.UserName.TrimStart('\')
        $ESXiPassword = $Credential.GetNetworkCredential().Password
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
    
                $DisableSSH = $false
                $HostName = $ESXiHost.ExtensionData.Config.Network.DnsConfig.HostName
                $DNSName = $HostName + "." + $ESXiHost.ExtensionData.Config.Network.DnsConfig.DomainName
                $ESXiSSLPath = "$ESXiUsername@$($DNSName):/etc/vmware/ssl"

                $RUICSR = "$CertPath\ESXi\$HostName\rui.csr"
                $TempRUIKey = "$CertPath\ESXi\$HostName\temprui.key"
                $ESXiCFG = "$CertPath\ESXi\$HostName\esxi.cfg"
                $RUIKey = "$CertPath\ESXi\$HostName\rui.key"
                $RUICRT = "$CertPath\ESXi\$HostName\rui.crt"
                $CertBackupFolder = "$CertPath\ESXi\$HostName\CertBackup"            

                if (!(Test-Path -Path "$CertPath\ESXi\$HostName")){

                    New-Item -Path "$CertPath\ESXi\$HostName" -ItemType Directory -Force | Out-Null
                }

                if (!(Test-Path -Path $CertBackupFolder)){

                    New-Item -Path $CertBackupFolder -ItemType Directory -Force | Out-Null
                }

                $ReqText = @"
[ req ]
default_bits = 2048
default_keyfile = rui.key
distinguished_name = req_distinguished_name
encrypt_key = no
prompt = no
string_mask = nombstr
req_extensions = v3_req

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment, dataEncipherment, nonRepudiation
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = DNS:$HostName, DNS:$DNSName

[ req_distinguished_name ]
countryName = $CountryName
stateOrProvinceName = $State
localityName = $Locality
0.organizationName = $Organization
commonName = $HostName
"@

                # --- Write the file with no additional blank line at the end
                [System.IO.File]::WriteAllText($ESXiCFG, $ReqText)

                # --- Create the certificate request rui.csr and temp private key
                Invoke-Expression "$OpenSSLEXE req -new -nodes -out $RUICSR -keyout $TempRUIKey -config $ESXiCFG" 2>&1

                # --- Convert the Key to be in RSA format
                Invoke-Expression "$OpenSSLEXE rsa -in $TempRUIKey -out $RUIKey" 2>&1

                # --- Submit the certificate request
                Invoke-Expression "certreq -submit -config $CAName -attrib $CertTemplate $RUICSR $RUICRT" 2>&1 | Out-Null

                # --- Enable SSH if necessary
                $SSHService = Get-VMHostService -VMHost $ESXIHost | Where-Object {$_.Key -eq "TSM-SSH"}

                if (!($SSHService.Running)){

                    $DisableSSH = $true
                    Start-VMHostService -HostService $SSHService -Confirm:$false | Out-Null
                }

                # --- Test SCP authentication with VMware host
                if (!($CheckAuth = Invoke-Expression "echo `"Y`" | $PSCPEXE -scp -pw $($ESXiPassword) -ls $($ESXiSSLPath)" 2>&1)){

                    throw "Unable to authenticate via SCP with $DNSName"
                }

                # --- Backup existing certs on the host
                Invoke-Expression "$PSCPEXE -scp -batch -pw $($ESXiPassword) `"$($ESXiSSLPath)/rui.key`" $CertBackupFolder" | Out-Null
                Invoke-Expression "$PSCPEXE -scp -batch -pw $($ESXiPassword) `"$($ESXiSSLPath)/rui.crt`" $CertBackupFolder" | Out-Null

                # --- Check backup was successful before continuing
                if(!((Test-Path "$CertBackupFolder\rui.key") -and (Test-Path "$CertBackupFolder\rui.crt"))){
    
                    throw "Cert backup was not successful for $DNSName"
                }

                # --- Upload new certs to the host
                Invoke-Expression "$PSCPEXE -scp -batch -pw $($ESXiPassword) $($RUIKey) $($ESXiSSLPath)" | Out-Null
                Invoke-Expression "$PSCPEXE -scp -batch -pw $($ESXiPassword) $($RUICRT) $($ESXiSSLPath)" | Out-Null


                # --- Disable SSH if enabled earlier
                if ($DisableSSH){

                    Stop-VMHostService -HostService $SSHService -Confirm:$false | Out-Null
                }

                # --- Restart the host to complete the switch over to the new certificate
                $ESXiHost | Restart-VMHost -Confirm:$false
            }
        }
        catch [Exception] {
            
            throw "Unable to update certificate on host"
        }
    }

    end {

    }
}