<#
.Synopsis
   This cmdlet is to find the uptime of the Azure Virtual Machine
.DESCRIPTION
   This cmdlet is to find the uptime of the Azure Virtual Machine
   For more information visit https://docs.microsoft.com/en-us/powershell/module/az.compute/get-azvm?view=azps-4.6.0
.EXAMPLE
   Get-AZVMBootTime -Name Windows10 -ResourceGroupName az104
   Get-AzVM | %{Get-AZVMBootTime -ResourceGroupName $_.ResourceGroupName -name $_.name}
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
    $BootTime=((Get-AzVM -ResourceGroupName $ResourceGroupName -Name $Name -Status).statuses[0].Time)
    #$uptime = (NEW-TIMESPAN –Start (get-date) –End ($BootTime)).AddHours(5.5)

                $Properties =      @{Name  = $Name
                                    BootTime = $BootTime
                                    #Uptime  = $uptime
                                    }
                              
                $Object = New-Object -TypeName PSObject -Property $Properties | Select Name,BootTime
                $Object
    }

    

}
