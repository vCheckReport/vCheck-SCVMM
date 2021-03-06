# Start of Settings
# Snapshot age threshold (days)
$SnapshotThreshold =" 7"
# End of Settings

$Title = "VMs with old snapshots"
$Header ="VMs with old snapshots"
$Comments = "Virtual Machines with snapshots older than $SnapshotThreshold days"
$Display = "Table"
$Author = "Jan Egil Ring"
$PluginVersion = 1.0
$PluginCategory = "SC VMM"

switch -wildcard ($VMMServer.ProductVersion) 
    { 
        "2.*" {Get-VMCheckpoint | Where-Object {$_.AddedTime -lt $date.AddDays(-$SnapshotThreshold) } | Select-Object AddedTime,VM,@{Name="VMHost";Expression={($_ | Select-Object -ExpandProperty VM).VMHost}},Description | Sort-Object AddedTime} 
        "3.*" {Get-SCVMCheckpoint | Where-Object {$_.AddedTime -lt $date.AddDays(-$SnapshotThreshold) } | Select-Object AddedTime,VM,@{Name="VMHost";Expression={($_ | Select-Object -ExpandProperty VM).VMHost}},Description | Sort-Object AddedTime} 
        default {break}
    }
