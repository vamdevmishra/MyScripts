# Powershell script to check Last Reboottime for multiple machines and send an email to the DL
# Author - vamdev mishra
# Version 1.0
# 

$computers = [Environment]::GetFolderPath("Desktop")+'\Machine_List.txt'
$report = @()
foreach($computer in $computers)
{
Try {

        $query = Get-CimInstance win32_operatingsystem  -ErrorAction stop -ComputerName $computer -Property lastbootuptime `
  
        $Properties = @{ComputerName  = $Computer
                        LastBoot      = $query.LastBootUpTime
                        }
                              
        $Object = New-Object -TypeName PSObject -Property $Properties | Select ComputerName, LastBoot

     }

Catch
        {
        Write-Host "running catch for $computer" -ForegroundColor Red
         
        $Properties = @{ComputerName  = $Computer
                        LastBoot = "Not Reachable"
                        }

       $Object = New-Object -TypeName PSObject -Property $Properties | Select ComputerName, LastBoot

        }

 $report += $object
}
#$Exporting the CSV File 
$report | Export-csv  [Environment]::GetFolderPath("Desktop")+'\Reboot.csv' -NoTypeInformation

#Sending the email

$emailSmtpUser = "user"
$emailSmtpPass = "P@ssw0rd"
$Cred = New-Object System.Net.NetworkCredential( $emailSmtpUser , $emailSmtpPass );
Send-MailMessage -From 'noreply@abc.com' -To 'serveradmin@abc.com' `
 -Subject 'Last Reboot of Servers' -Body "Hi team, Please find the attached list of lastreboot of the servers, please take action on the servers which are Not Reachable" `
 -Attachments [Environment]::GetFolderPath("Desktop")+'\Reboot.csv'  -SmtpServer 'smtp.abc.com' -Credential $cred
