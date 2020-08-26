<#
.Synopsis
   This cmdlet is to find the uptime of the Azure Virtual Machine
.DESCRIPTION
   This cmdlet is to find the uptime of the Azure Virtual Machine
   For more information visit https://docs.microsoft.com/en-us/powershell/module/az.compute/get-azvm?view=azps-4.6.0
.EXAMPLE
   Get-AZVMBootTime -Name Windows10 -ResourceGroupName az104
   Get-AzVM | %{Get-AZVMBootTime -ResourceGroupName $_.ResourceGroupName -name $_.name} |ft
.
#>
function Get-AZVMBootTime
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$True,
                   Position=0)]
        $Name,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$false,
                   Position=1)]
        $ResourceGroupName
    )

    Process
    {
    $vm=Get-AzVM -ResourceGroupName $ResourceGroupName -Name $Name -Status
    if($vm.Statuses[1].DisplayStatus -eq "VM deallocated" )
    {
    $uptime = "Not Applicable"
    }
    else
    {
    $uptime = (New-Timespan –Start (($vm.statuses[0].Time).AddHours(5.5)) –End (get-date)).minutes
    }

                $Properties =      @{Name  = $Name
                                    OsName =$vm.OsName
                                    ResourceGroupName =$vm.ResourceGroupName
                                    VMStatus =$vm.Statuses[1].DisplayStatus
                                    BootTime  = $vm.statuses[0].Time
                                    UPtime_Minutes = $uptime
                                    }
                              
                $Object = New-Object -TypeName PSObject -Property $Properties | Select Name,OsName,Resourcegroupname,vmstatus,boottime,uptime_minutes 
                $Object
    }

    

}
