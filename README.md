# PowerCLITools Community Module

PowerCLITools provides additional functions via a PowerShell module to use with PowerCLI from VMware.

It is formed from a set of functions that I have built up over time from consulting experiences in the field and essentially plugs a few gaps in the coverage of PowerCLI.

**Pre-Requisites**

PowerShell version 4 or later.

Ensure that VMware PowerCLI is installed. Functions have been tested against v5.8 R1.


**Installation**


1) Download all files comprising the module. **Ensure the files are unblocked**.

2) Create a folder for the module in your module folder path, e.g. C:\Users\username\Documents\WindowsPowerShell\Modules\PowerCLITools

3) Place the module files in the above folder


**Usage**

The below command will make all of the functions in the module available

Import-Module PowerCLITools

To see a list of available functions:

Get-Command -Module PowerCLITools

                         
Add-vCenterLicense            
Get-ClusterAverageCpuMemory   
Get-CurrentVIServer           
Get-SnapshotCreator           
Get-vCenterLicense            
Get-VMCreationDate            
Get-VMDiskData                
Get-VMHostAlarm               
Get-VMHostDumpCollector       
Get-VMHostiSCSIBinding        
Get-VMHostLicense             
Get-VMHostNetworkAdapterCDP   
Get-VMHostSyslogConfig        
Get-VMIPAddressFromNetwork    
Get-VMSCSIID                  
Install-vSphereClient         
Install-vSpherePowerCLI       
New-vCenterPermission         
New-vCenterRole               
New-VMFromSnapshot            
Remove-vCenterLicense         
Set-VMHostDumpCollector       
Set-VMHostiSCSIBinding        
Set-VMHostLicense             
Set-VMHostSyslogConfig        
Set-VMHostToCurrentDateandTime
Test-VIServerConnection       
Update-ESXiSSL                
Update-VMNotesWithOwner       
Update-VMScsiDeviceOrder


**Nested Modules**

You will note that each function is itself a nested module of the PowerCLITools module. In this [blog post](www.jonathanmedd.net/2013/11/powercli-in-the-enterprise-breaking-the-magicians-code-function-templates.html) I describe why I make my modules like this.




**VI Properties**

If you take a look inside the PowerCLITools.Initialise.ps1 file you'll notice a number of VI Properties. Some of these are required by some of the functions in the module and some are just there for my convenience and make using my PowerCLI session simpler. You can add and remove VI Properties as to your own personal preference, but watch out that some are actually needed.  You can find out more about VI Properties [here](http://blogs.vmware.com/PowerCLI/2011/08/ability-to-customize-vi-objects.html).

