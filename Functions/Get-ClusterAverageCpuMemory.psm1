function Get-ClusterAverageCpuMemory {
<#
    .SYNOPSIS
    Get average CPU and Memory stats for a vSphere cluster
    
    .DESCRIPTION
    Get average CPU and Memory stats for a vSphere cluster
    
    .PARAMETER Name
    A vSphere Cluster object

    .PARAMETER PeakStartHour
    Hour that Peak stats should be calculated from, e.g. 8

    .PARAMETER PeakEndHour
    Hour that Peak stats should be calculated to, e.g. 18

    .PARAMETER Day
    Day of the month, e.g. 10

    .PARAMETER Month
    Month of the year, e.g. 8

    .PARAMETER Year
    Year, e.g. 2013

    .INPUTS
    System.Management.Automation.PSObject
    System.Int
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    PS> Get-ClusterAverageCpuMemory -Name Cluster01 -PeakStartHour 8 -PeakEndHour 18 -Day 10 -Month 8 -Year 2013
    
    .EXAMPLE
    PS> Get-Cluster Cluster01  | Get-ClusterAverageCpuMemory -PeakStartHour 8 -PeakEndHour 18 -Day 10 -Month 8 -Year 2013
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$Name,    
    
    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [Int]$PeakStartHour,

    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [Int]$PeakEndHour,

    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [Int]$Day,

    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [Int]$Month,

    [parameter(Mandatory=$true,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [Int]$Year
    )    

    begin {
        

        $DaysInMonth = [DateTime]::DaysInMonth($Year, $Month)
        $IsLeapYear = [DateTime]::IsLeapYear($Year)

        if ($IsLeapYear){
            $LastDayOfYear = 366
        }
        else {
            $LastDayOfYear = 365
        }

        $PeakStart = Get-Date -Year $Year -Month $Month -Day $Day -Hour $PeakStartHour -Minute 0 -Second 0
        $PeakEnd = Get-Date -Year $Year -Month $Month -Day $Day -Hour ($PeakEndHour - 1) -Minute 59 -Second 59
        $OffPeakStart = Get-Date -Year $Year -Month $Month -Day $Day -Hour $PeakEndHour -Minute 0 -Second 0


        if (((Get-Date -Year $Year -Month $Month -Day $Day).DayOfYear) -eq $LastDayOfYear){

            $OffPeakEnd = Get-Date -Year ($Year +1) -Month 1 -Day 1 -Hour ($PeakStartHour -1) -Minute 59 -Second 59
        }
        elseif ($Day -eq $DaysInMonth){

            $OffPeakEnd = Get-Date -Year $Year -Month ($Month + 1) -Day 1 -Hour ($PeakStartHour -1) -Minute 59 -Second 59
        }
        else {

            $OffPeakEnd = Get-Date -Year $Year -Month $Month -Day ($Day + 1) -Hour ($PeakStartHour -1) -Minute 59 -Second 59
        }        

        $OutputObject = @()
    }
    
    process {
    

        try {

            
            foreach ($Cluster in $Name){
                
                if ($Cluster.GetType().Name -eq "string"){
                
                    try {
                        $Cluster = Get-Cluster $Cluster -ErrorAction Stop
                    }
                    catch [Exception]{
                        Write-Warning "Cluster $Cluster does not exist"
                        continue
                    }
                }
                
                elseif ($Cluster -isnot [VMware.VimAutomation.ViCore.Impl.V1.Inventory.ClusterImpl]){
                    Write-Warning "You did not pass a string or a Cluster object"
                    continue
                }
                

                $TotalCPUMHZ = $Cluster.TotalCPUGhz * 1000

                $PeakCPUStatAverage = $Cluster | Get-Stat -Start $PeakStart -Finish $PeakEnd -Stat cpu.usagemhz.average -IntervalSecs 4500 | Measure-Object value -Average
                $PeakCPUStatResult = [math]::round(($PeakCPUStatAverage.Average / $TotalCPUMHZ *100), 0)

                $OffPeakCPUStatAverage = $Cluster | Get-Stat -Start $OffPeakStart -Finish $OffPeakEnd -Stat cpu.usagemhz.average -IntervalSecs 4500 | Measure-Object value -Average
                $OffPeakCPUStatResult = [math]::round(($OffPeakCPUStatAverage.Average / $TotalCPUMHZ *100), 0)

                $PeakMemoryStatAverage = $Cluster | Get-Stat -Start $PeakStart -Finish $PeakEnd -Stat mem.usage.average -IntervalSecs 4500 | Measure-Object value -Average
                $PeakMemoryStatResult = [math]::round($PeakMemoryStatAverage.Average, 0)

                $OffPeakMemoryStatAverage = $Cluster | Get-Stat -Start $OffPeakStart -Finish $OffPeakEnd -Stat mem.usage.average -IntervalSecs 4500  | Measure-Object value -Average
                $OffPeakMemoryStatResult = [math]::round($OffPeakMemoryStatAverage.Average, 0)
                
                $hash = @{                        
                    
                    Cluster = $Cluster
                    PeakCPUStatResult = $PeakCPUStatResult
                    OffPeakCPUStatResult = $OffPeakCPUStatResult
                    PeakMemoryStatResult = $PeakMemoryStatResult
                    OffPeakMemoryStatResult = $OffPeakMemoryStatResult

                }
                $Object = New-Object PSObject -Property $hash
                $OutputObject += $Object
            }
        }
        catch [Exception]{
        
            throw "Unable to get Cluster CPU and Memory Stats"
        }    
    }
    end {
        Write-Output $OutputObject
    }
}