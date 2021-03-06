$Title = "Dynamically Expanding Disks Consolidation Forecast"
$Header ="Dynamically Expanding Disks Consolidation Forecast"
$Comments = "Estimatation of disk space needed to convert all Virtual Disks of type 'DynamicallyExpanding' to type 'FixedSize'"
$Display = "Table"
$Author = "Jan Egil Ring"
$PluginVersion = 1.0
$PluginCategory = "SC VMM"

switch -wildcard ($VMMServer.ProductVersion) 
    { 
        "2.*" {$DynamicallyExpandingDisks = $VMs | Get-VirtualHardDisk | Where-Object {$_.VHDType -eq "DynamicallyExpanding"}} 
        "3.*" {$DynamicallyExpandingDisks = $VMs | Get-SCVirtualHardDisk | Where-Object {$_.VHDType -eq "DynamicallyExpanding"}} 
        default {break}
    }

$TotalSize = 0
$TotalMaximumSize = 0
$TotalDisks = 0


if ($DynamicallyExpandingDisks) {

$DynamicallyExpandingDisks | ForEach-Object {
$TotalSize += $_.Size
$TotalMaximumSize += $_.MaximumSize
$TotalDisks ++
}

New-Object -TypeName pscustomobject -Property @{
"Number of dynamically expanding disks" = $TotalDisks
"Total size of dynamically expanding disks" = ("{0:N0}" -f ($TotalSize / 1gb) + " GB")
"Total maximumsize of dynamically expanding disks" = ("{0:N0}" -f ($TotalMaximumSize / 1gb) + " GB")
}
}