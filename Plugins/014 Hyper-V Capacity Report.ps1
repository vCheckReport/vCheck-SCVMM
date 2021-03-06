# Start of Settings
$VMAverageDiskSizeInGB = "40"
$VMAverageMemoryinGB =" 2"
$VMAverageCPUCount = "1"
# End of Settings

$Title = "Hyper-V 2008 R2 SP1 Capacity Report"
$Header ="Hyper-V 2008 R2 SP1 Capacity Report"
$Comments = "Estimated Hyper-V 2008 R2 SP1 Capacity Report based on official documentation: http://technet.microsoft.com/en-us/library/ee405267%28WS.10%29.aspx"
$Comments = "Estimated number of new virtual machine based on a baseline with $VMAverageCPUCount vCPU, $VMAverageMemoryinGB GB memory and $VMAverageDiskSizeInGB GB harddisk."
$Display = "Table"
$Author = "Jan Egil Ring"
$PluginVersion = 1.0
$PluginCategory = "Hyper-V"

$FailoverClusters = $VMHostClusters | Where-Object {$_.VirtualizationPlatform -eq "HyperV"}

if ($FailoverClusters) {

foreach ($cluster in $FailoverClusters) {

Write-Verbose "Processing cluster $($cluster.name)"

$HyperV2008R2SP1Cluster = $true

foreach ($VMHost in ($cluster.nodes)) {

Write-Verbose "Processing VMHost $($VMHost)"

if ($VMHost.HyperVVersion.Major -ne "6" -or $VMHost.HyperVVersion.Minor -ne "1" -or $VMHost.HyperVVersion.Build -ne "7601"){
$HyperV2008R2SP1Cluster = $false
}

        }
        
if ($HyperV2008R2SP1Cluster) {

###############
switch -wildcard ($VMMServer.ProductVersion) 
    { 
        "2.*" {$VMs = $cluster.nodes | Get-VM} 
        "3.*" {$VMs = $cluster.nodes | Get-SCVirtualMachine} 
        default {break}
    }


$TotalMemory = 0
$AvailableMemory = 0
$LogicalCPUCount = 0
$SharedVolumesCapacity = 0
$SharedVolumesFreeSpace = 0
$VirtualCPUCount = 0

$cluster.nodes | ForEach-Object {$TotalMemory += $_.TotalMemory}
$cluster.nodes | ForEach-Object {$AvailableMemory += $_.AvailableMemory}
$cluster.nodes | ForEach-Object {$LogicalCPUCount += $_.LogicalCPUCount}
$cluster.sharedvolumes | ForEach-Object {$SharedVolumesCapacity += $_.Capacity}
$cluster.sharedvolumes | ForEach-Object {$SharedVolumesFreeSpace += $_.FreeSpace}
$VMs | ForEach-Object {$VirtualCPUCount += $_.CPUCount}
if ($cluster.clusterreserve -gt 1) {
$clusterreserve = $cluster.clusterreserve
} else {
$clusterreserve = 1
}

$AvgAvailableMemoryGB = ($AvailableMemory/1kb)/$cluster.nodes.count
$TotalAvailableMemoryWithHostReserveGB = $AvgAvailableMemoryGB * ($cluster.nodes.count - $clusterreserve)

$AvgMemory = ($TotalMemory/1gb)/$cluster.nodes.count
$TotalAvailableMemoryWithHostReserve = ($AvgMemory * ($cluster.nodes.count - $clusterreserve)) - (($TotalMemory/1gb)-($AvailableMemory/1kb))

if ($TotalAvailableMemoryWithHostReserve -gt 0) {
$NewVMsMemoryWithHostReserve = "{0:N0}" -f ($TotalAvailableMemoryWithHostReserve/$VMAverageMemoryinGB)
}
else {
$overcommit = [math]::round($TotalAvailableMemoryWithHostReserve)
$NewVMsMemoryWithHostReserve = "0 (overcommitment: $overcommit GB)"
}

$VirtualCPUCapacity = $LogicalCPUCount*8
$VirtualCPUCapacityAvg = $LogicalCPUCount*8/$cluster.nodes.count
$VirtualCPUCapacityWithHostReserve = $VirtualCPUCapacity-($VirtualCPUCapacityAvg*$clusterreserve) - $VirtualCPUCount

if ($VirtualCPUCapacityWithHostReserve -gt 0) {
$NewVMsCPUWithHostReserve = $VirtualCPUCapacityWithHostReserve/$VMAverageCPUCount
}
else {
$NewVMsCPUWithHostReserve = "0 (overcommitment: $VirtualCPUCapacityWithHostReserve vCPUs"
}


Write-Verbose "Cluster reserve is: $clusterreserve"

New-Object -TypeName pscustomobject -Property @{
Name = $cluster.name
Type = "Cluster"
"New VMs based on CPU" = ($LogicalCPUCount*8 - $VirtualCPUCount)/$VMAverageCPUCount
"New VMs based on memory" = "{0:N0}" -f (($AvailableMemory/1kb)/$VMAverageMemoryinGB)
"New VMs based on CPU (with host reserve)" = $NewVMsCPUWithHostReserve
"New VMs based on memory (with host reserve)" = $NewVMsMemoryWithHostReserve
"New VMs based on storage" = "{0:N0}" -f (($SharedVolumesFreeSpace/1gb)/$VMAverageDiskSizeInGB)
} | Select-Object Name,Type,"New VMs based on CPU","New VMs based on memory","New VMs based on CPU (with host reserve)","New VMs based on memory (with host reserve)","New VMs based on storage"


###############


}

    }

}


switch -wildcard ($VMMServer.ProductVersion) 
    { 
        "2.*" {$StandaloneHosts = Get-VMHost | Where-Object {$_.VirtualizationPlatform -eq "HyperV" -and $_.HyperVVersion -like "6.1.7601.*" -and (-not $_.HostCluster)}} 
        "3.*" {$StandaloneHosts = Get-SCVMHost | Where-Object {$_.VirtualizationPlatform -eq "HyperV" -and $_.HyperVVersion -like "6.1.7601.*" -and (-not $_.HostCluster)}} 
        default {break}
    }


if ($StandaloneHosts) {

foreach ($VMHost in $StandaloneHosts) {

switch -wildcard ($VMMServer.ProductVersion) 
    { 
        "2.*" {$VMs = $VMHost | Get-VM} 
        "3.*" {$VMs = $VMHost | Get-SCVirtualMachine} 
        default {break}
    }

$VirtualCPUCount = 0
$VMs | ForEach-Object {$VirtualCPUCount += $_.CPUCount}

New-Object -TypeName pscustomobject -Property @{
Name = $VMHost.name
Type = "Standalone"
"New VMs based on CPU" = ($LogicalCPUCount*8 - $VirtualCPUCount)/$VMAverageCPUCount
"New VMs based on memory" = "{0:N0}" -f (($vmhost.AvailableMemory/1kb)/$VMAverageMemoryinGB)
"New VMs based on CPU (with host reserve)" = "N/A (standalone host)"
"New VMs based on memory (with host reserve)" = "N/A (standalone host)"
"New VMs based on storage" = "{0:N0}" -f (($vmhost.AvailableStorageCapacity/1gb)/$VMAverageDiskSizeInGB)
} | Select-Object Name,Type,"New VMs based on CPU","New VMs based on memory","New VMs based on CPU (with host reserve)","New VMs based on memory (with host reserve)","New VMs based on storage"


    }
}
