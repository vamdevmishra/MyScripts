<#NOTES
        Copyright (c) Vamdev Mishra, SR Consultant Microsoft Corporation.  All rights reserved.
        Use of this sample source code is subject to the terms of the Microsoft
        license agreement under which you licensed this sample source code. If
        you did not accept the terms of the license agreement, you are not
        authorized to use this sample source code. For the terms of the license,
        please see the license agreement between you and Microsoft or, if applicable,
        see the LICENSE.RTF on your install media or the root of your tools installation.
        THE SAMPLE SOURCE CODE IS PROVIDED "AS IS", WITH NO WARRANTIES.
        Please run it in Test Environment First to evaluate the results.
      #>


#first store the backed up gpo in below folder using below line of code from the source domain.
#Backup-GPO -All -Path 'C:\Temp\GPOsBackup' | out-null
#"C:\Temp\GPOsbackup"

if(!(Test-Path -Path 'C:\Temp\GPOsBackup'))
                       {
                        New-Item -ItemType Directory -Name "GPOsBackup" -Path "C:\Temp" | Out-Null
                       }

$BackupGPOs= (Get-ChildItem 'C:\Temp\GPOsBackup').fullName
foreach($GPO in $BackupGPOs)
{
    $file = (Get-ChildItem $GPO -Include "gpreport.xml" -Recurse).fullname
    $GPOguid=($file.Split("\")[-2].replace("}","")) -replace "{"
    $GPOContentinXML= [XML] (Get-Content $file)
    $GPODisplayName= $GPOContentinXML.GPO.Name

     Try 
                {
                 New-GPO -Name $GPODisplayName -ErrorAction Stop | Out-Null
                 Write-Host "GPO $GPODisplayName created successfully." -ForegroundColor Green

                 Try
                 {
                   
                   Import-GPO -BackupGpoName $GPODisplayName -TargetName $GPODisplayName -Path 'C:\Temp\GPOsBackup' -ErrorAction Stop | Out-Null
                   Write-Host "GPO $GPODisplayName Imported Successfully." -ForegroundColor Green
                 }
                Catch 
                    {
                      Write-Host "GPO $GPODisplayName Couldn't be Imported." -ForegroundColor Red
                      Write-Host $_.exception.message
                    }

                 } #firsttryclosed
                 Catch
                 {
                  Write-Host "GPO $GPODisplayName couldn't be created." -ForegroundColor Red
                  Write-Host $_.exception.message
                 } #firstcatchclosed

}
