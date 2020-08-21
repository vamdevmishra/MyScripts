# Powershell script to check UserInfo using CSV File and output to CSV File
# Author - Vamdev Mishra
# Version 1.0
# 
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$users = import-csv "$DesktopPath\User_input.csv"
$report = @()
foreach($user in $users.username)
{
Try {
        Write-Host "Running Query for User $user" -ForegroundColor Green 
        $query = get-aduser $user -ErrorAction stop  -Property name,displayname,samaccountname `
  
        $Properties = @{Query  = $user
                        Name      = $query.name
                        SamAccountName= $query.SamAccountName
                        }
                              
        $Object = New-Object -TypeName PSObject -Property $Properties | Select Query, Name,samaccountname

     }

Catch
        {
        Write-Host "Unable to Query User $user" -ForegroundColor Red
         
        $Properties = @{Query  = $user
                        Name      = "Account Doesn't Exist in AD"
                        SamAccountName= "Account Doesn't Exist in AD"
                        }

       $Object = New-Object -TypeName PSObject -Property $Properties | Select Query, Name,SamAccountName

        }

 $report += $object
}
#$Exporting the CSV File 
$report | Export-csv $DesktopPath\User_Report.csv -NoTypeInformation
Write-Host opening the output file stored at -> $DesktopPath\User_Report.csv, script completed -ForegroundColor Yellow
notepad.exe "$DesktopPath\User_Report.csv"