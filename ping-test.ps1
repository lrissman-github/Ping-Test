###############
#  Ping-Test  #
###############

#  Intended use of this script is to record ping times from hosts into a csv to help detect inconsistant latency  
# Major portions of this script taken from here: https://community.spiceworks.com/topic/337701-ping-via-powershell-log-results-with-timestamp


# June 7th, 2016 - Initial Creation



# Script will ping each host and record the data to a csv 

#output format is:  "TimeStamp","Source","Destination","IPV4Address","Status","ResponseTime"
#TimeStamp - Time the ping started
#Source - Source IP
#Destination - Destination supplied to the script (NAme, or ip)
#IPV4Address - IPV4 Address of Destination
#Status - Failed or NULL  (Timed out)
#Responsetime = ms response or NULL if Failed (Timed out)

[CmdletBinding()]
Param (
    [int32]$Count = 5,  # Number of pings
    
    [Parameter(ValueFromPipeline=$true)]
    [String[]]$Computer = "127.0.0.1",
    
    [string]$LogPath = ".\pinglog.csv"
)

#Variable initalization 
$Ping = @() #Initalize the array

#Test if path exists, if not, create it
If (-not (Test-Path (Split-Path $LogPath) -PathType Container))
{   Write-Verbose "Folder doesn't exist $(Split-Path $LogPath), creating..."
    New-Item (Split-Path $LogPath) -ItemType Directory | Out-Null
}

#Test if log file exists, if not seed it with a header row
If (-not (Test-Path $LogPath))
{   Write-Verbose "Log file doesn't exist: $($LogPath), creating..."
    Add-Content -Value '"TimeStamp","Source","Destination","IPV4Address","Status","ResponseTime"' -Path $LogPath
}

#Log collection loop
Write-Verbose "Beginning Ping monitoring of $Comptuer for $Count tries:"
While ($Count -gt 0)
{   
    $Ping = Get-WmiObject Win32_PingStatus -Filter "Address = '$Computer'" | Select @{Label="TimeStamp";Expression={Get-Date}},@{Label="Source";Expression={ $_.__Server }},@{Label="Destination";Expression={ $_.Address }},IPv4Address,@{Label="Status";Expression={ If ($_.StatusCode -ne 0) {"Failed"} Else {""}}},ResponseTime
    $Result = $Ping | Select TimeStamp,Source,Destination,IPv4Address,Status,ResponseTime
    if ($Result.status -eq "Failed" ) {
        $Result.ResponseTime = 9999999
    }
    Write-verbose ($Result | Format-Table -AutoSize | Out-String)
    $ResultCSV = $Result | ConvertTo-Csv -NoTypeinformation
    Start-Sleep -Seconds 1
    $count--
    $ResultCSV[1] | Add-Content -Path $LogPath
}
