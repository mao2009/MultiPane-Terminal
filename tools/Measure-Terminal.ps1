#requires -Version 5.1
<#
.SYNOPSIS
 Samples memory/CPU for one terminal host and its descendants.
.EXAMPLE
 .\tools\Measure-Terminal.ps1 -HostProcessId 12345 -DurationSeconds 60 -OutputCsv .\results\sample.csv
.NOTES
 CPU values are cumulative processor seconds; take differences between samples.
 Descendant mapping relies on Win32_Process.ParentProcessId, which can be affected by PID reuse.
 WSL VM memory and GPU allocation are NOT accounted for by this script.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateRange(1,2147483647)][int]$HostProcessId,
    [ValidateRange(1,86400)][int]$DurationSeconds = 60,
    [ValidateRange(1,60)][int]$IntervalSeconds = 1,
    [string]$OutputCsv = ".\results\terminal-process-samples.csv"
)
$ErrorActionPreference = 'Stop'
$target = [IO.Path]::GetFullPath($OutputCsv)
$directory = Split-Path -Parent $target
if (-not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}
$rows = New-Object 'System.Collections.Generic.List[object]'
$timeStart = [DateTimeOffset]::UtcNow
do {
    $timestamp = [DateTimeOffset]::UtcNow.ToString('o')
    $cim = @(Get-CimInstance Win32_Process | Select-Object ProcessId, ParentProcessId, Name, CreationDate)
    $children = @{}
    foreach ($p in $cim) {
        $parent = [int]$p.ParentProcessId
        if (-not $children.ContainsKey($parent)) { $children[$parent] = New-Object 'System.Collections.Generic.List[int]' }
        $children[$parent].Add([int]$p.ProcessId)
    }
    $seen = New-Object 'System.Collections.Generic.HashSet[int]'
    $queue = New-Object 'System.Collections.Generic.Queue[int]'
    $queue.Enqueue($HostProcessId)
    while ($queue.Count -gt 0) {
        $pidValue = $queue.Dequeue()
        if (-not $seen.Add($pidValue)) { continue }
        if ($children.ContainsKey($pidValue)) {
            foreach ($child in $children[$pidValue]) { $queue.Enqueue($child) }
        }
    }
    foreach ($id in $seen) {
        $procEntry = $cim | Where-Object { $_.ProcessId -eq $id } | Select-Object -First 1
        if (-not $procEntry) { continue }
        try {
            $process = [Diagnostics.Process]::GetProcessById($id)
            $rows.Add([pscustomobject]@{
                TimestampUtc = $timestamp
                HostPid = $HostProcessId
                ProcessId = $id
                ParentProcessId = $procEntry.ParentProcessId
                ProcessName = $procEntry.Name
                PrivateBytes = $process.PrivateMemorySize64
                WorkingSetBytes = $process.WorkingSet64
                VirtualBytes = $process.VirtualMemorySize64
                CpuSecondsCumulative = $process.TotalProcessorTime.TotalSeconds
                ThreadCount = $process.Threads.Count
                HandleCount = $process.HandleCount
            })
        } catch {
            Write-Verbose ("Process {0} exited during sampling" -f $id)
        }
    }
    Start-Sleep -Seconds $IntervalSeconds
} while (([DateTimeOffset]::UtcNow - $timeStart).TotalSeconds -lt $DurationSeconds)
$rows | Export-Csv -LiteralPath $target -NoTypeInformation -Encoding UTF8
Write-Host ("Saved {0} process samples: {1}" -f $rows.Count, $target)
