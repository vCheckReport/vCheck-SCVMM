# Start of Settings
# Free space threshold for Hyper-V Cluster Shared Volumes (value in percent)
$CSVFreeSpaceThreshold =" 10"
# End of Settings

$Title = "Hyper-V Cluster Shared Volumes"
$Header ="Hyper-V Cluster Shared Volumes"
$Comments = "Hyper-V Cluster Shared Volumes with less than $CSVFreeSpaceThreshold percent free space"
$Display = "Table"
$Author = "Jan Egil Ring"
$PluginVersion = 1.0
$PluginCategory = "Hyper-V"

$FailoverClusters = $VMHostClusters | Where-Object {$_.VirtualizationPlatform -eq "HyperV"}

if ($FailoverClusters)  {

if (!(Get-Module FailoverClusters)) {
	Import-Module FailoverClusters
}

foreach ($cluster in $FailoverClusters) {

Get-ClusterSharedVolume -Cluster $cluster.name | Select-Object -Property Name -ExpandProperty SharedVolumeInfo | Where-Object {$_.Partition.PercentFree -lt $CSVFreeSpaceThreshold} | Select-Object @{Name="Cluster";e={$cluster.name}},Name,FriendlyVolumeName,@{ Label = "Size(GB)" ; Expression = { "{0:N2}" -f ($_.Partition.Size/1024/1024/1024) } },@{ Label = "PercentFree" ; Expression = { "{0:N2}" -f ($_.Partition.PercentFree) } },@{ Label = "FreeSpace(GB)" ; Expression = { "{0:N2}" -f ($_.Partition.FreeSpace/1024/1024/1024) } },@{ Label = "UsedSpace(GB)" ; Expression = { "{0:N2}" -f ($_.Partition.UsedSpace/1024/1024/1024) } }

}
}
