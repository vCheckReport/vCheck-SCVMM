$Title = "Hyper-V Integration Components Version"

$Header ="Hyper-V Integration Components Version"

$Comments = "Hyper-V Virtual Machines with missing or out-dated Integration Services"

$Display = "Table"

$Author = "Jan Egil Ring"

$PluginVersion = 1.0

$PluginCategory = "Hyper-V"



# This plugin is based on the following script:

# http://blogs.msdn.com/b/robertvi/archive/2010/10/11/a-script-to-check-the-integration-services-version-on-hyper-v-host-and-guests.aspx



function Get-VMICVersion {

          [CmdletBinding()]

          Param(

              [Parameter(Mandatory=$true)]

              [string[]]$vmhost

          )

          Process

          {



# Defines import filter.

 filter Import-CimXml

 {

 $cimXml = [XML]$_

 $cimTree = New-Object -TypeName System.Object

 foreach ($cimProperty in $cimXml.SelectNodes("/INSTANCE/PROPERTY"))

 {$cimTree | Add-Member -MemberType NoteProperty -Name $cimProperty.NAME -Value $cimProperty.VALUE}

 $cimTree

 }



# Retrieves all VMs except host itself.

 foreach($hostName in $vmhost)

 {



# When using an small array please disable $hostName = $hostName.name

 #$hostName = $hostName.name

 If ((Get-SCVMHost -ComputerName $hostName).OverallState -eq "OK"){

 $hostSession = new-pssession -computername $hostname

 $icVersionParent = invoke-command -session $hostSession -scriptblock {Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\GuestInstaller" | ForEach-Object {Get-ItemProperty $_.pspath} | select-object "Microsoft-Hyper-V-Guest-Installer"}



 IF ((Get-SCVMHost -ComputerName $hostName).hypervversion -eq "6.1.7601.17514") {
          $guests = Get-WmiObject -Namespace root\virtualization -ComputerName $hostName -Query "SELECT * FROM Msvm_ComputerSystem WHERE EnabledState=2 AND NOT Caption LIKE 'Hosting Computer System'"
         }

 IF ((Get-SCVMHost -ComputerName $hostName).hypervversion -like "6.2.*") {
         $guests = Get-WmiObject -Namespace root\virtualization\v2 -ComputerName $hostName -Query "SELECT * FROM Msvm_ComputerSystem WHERE EnabledState=2 AND NOT Caption LIKE 'Hosting Computer System'"
       }

 IF ((Get-SCVMHost -ComputerName $hostName).hypervversion -like "6.3.*") {
          $guests = Get-WmiObject -Namespace root\virtualization\v2 -ComputerName $hostName -Query "SELECT * FROM Msvm_ComputerSystem WHERE EnabledState=2 AND NOT Caption LIKE 'Hosting Computer System'"
      }




 Remove-pssession -computername $hostname



 # Processes all guests.

 foreach($guestName in $guests)

 {



 Try {


IF ((Get-SCVMHost -ComputerName $hostName).hypervversion -eq "6.1.7601.17514") {
           $guestKVP = Get-WmiObject -Namespace root\virtualization -ComputerName $hostName -Query "ASSOCIATORS OF {$guestName} WHERE AssocClass=Msvm_SystemDevice ResultClass=Msvm_KvpExchangeComponent" -ErrorAction Stop
         }

 IF ((Get-SCVMHost -ComputerName $hostName).hypervversion -like "6.2.*") {
          $guestKVP = Get-WmiObject -Namespace root\virtualization\v2 -ComputerName $hostName -Query "ASSOCIATORS OF {$guestName} WHERE AssocClass=Msvm_SystemDevice ResultClass=Msvm_KvpExchangeComponent" -ErrorAction Stop
       }

 IF ((Get-SCVMHost -ComputerName $hostName).hypervversion -like "6.3.*") {
           $guestKVP = Get-WmiObject -Namespace root\virtualization\v2 -ComputerName $hostName -Query "ASSOCIATORS OF {$guestName} WHERE AssocClass=Msvm_SystemDevice ResultClass=Msvm_KvpExchangeComponent" -ErrorAction Stop
      }





 $icVersionGuest = $guestKVP.GuestIntrinsicExchangeItems | Import-CimXml | Where-Object{$_.Name -eq 'IntegrationServicesVersion'}



 $ichost = $icVersionParent.'Microsoft-Hyper-V-Guest-Installer'

 $icguest = $icVersionGuest.Data

 

 #Create hash-table for each virtual machine

$vminfo = @{}

$vminfo.hostname = $hostname

$vminfo.hostversion = $ichost

$vminfo.guestname = $guestName.ElementName



 If ($ichost -eq $icguest)



 {

 $vminfo.compliant = "Yes"

 }

 Else 



 {

 $vminfo.compliant = "No"

 }

 

  If ($icguest)



 {

 $vminfo.guestversion = $icguest

 }

 Else 



 {

 $vminfo.guestversion = "Not available"

 }

 

 #Create a new object for each virtual machine, based on the vminfo hash-table

 New-Object -TypeName PSObject -Property $vminfo

 

}







 Catch {

 #Write-host $hostName,$ichost 'Host contains no running guests' -foregroundcolor red

 }

 }

 }

 }

 }

 }

foreach ($VMHost in ($VMHosts | Where-Object {$_.VirtualizationPlatform -eq "HyperV"})) {



Get-VMICVersion -vmhost $VMHost.name | Where-Object {$_.guestversion -ne $_.hostversion} | Sort-Object guestname | Select-Object HostName,GuestName,HostVersion,GuestVersion,Compliant



}
