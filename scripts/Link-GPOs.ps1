<#NOTES
        Copyright (c) Vamdev, Mishra SR Consultant, Microsoft Corporation.  All rights reserved.
        Use of this sample source code is subject to the terms of the Microsoft
        license agreement under which you licensed this sample source code. If
        you did not accept the terms of the license agreement, you are not
        authorized to use this sample source code. For the terms of the license,
        please see the license agreement between you and Microsoft or, if applicable,
        see the LICENSE.RTF on your install media or the root of your tools installation.
        THE SAMPLE SOURCE CODE IS PROVIDED "AS IS", WITH NO WARRANTIES.
        Please run it in Test Environment First to evaluate the results.
      #>

#First store the backed up gpo in below folder using below line of code from the source domain.
#Backup-GPO -All -Path 'C:\Temp\GPOsBackup' | out-null
#"C:\Temp\GPOsbackup"
#Also change $domainnametoremove="domain.com" line #19 with your backup source domain name.

$hardcodedpathforGPOsbackup= "C:\Temp\GPOsbackup"
$domainnametoremove="contoso.com"
$files = (Get-ChildItem $hardcodedpathforGPOsbackup -Include "gpreport.xml" -Recurse).fullname
$Details = @()
foreach($file in $files)
{
    
    $GPOguid=($file.Split("\")[-2].replace("}","")) -replace "{"
    $GPOContentinXML= [XML] (Get-Content $file)
    $GPODisplayName= $GPOContentinXML.GPO.Name
    $Enable=if($GPOContentinXML.gpo.LinksTo -ne $null) {$True} else {$False}
    $LinkedTo=($GPOContentinXML.GPO.LinksTo.SOMPATH) 
    if($LinkedTo -ne $null)
    {
    $resolvedpaths= @()
    foreach($linkedgpo in $linkedto)
        { 
        
       Try
       
          {
            $path=(($linkedgpo -replace($domainnametoremove,'')  -replace('/',',OU=')).substring(1)) 
            $splits=$path.split(',')
            [array]::Reverse($splits)
            $fqdnpath=($splits -join ',')+","+$((Get-ADRootDSE).defaultNamingContext)
            $resolvedpaths = ($resolvedpaths+$fqdnpath)
            }

            Catch
                {
                 Write-Host "Couldn't convert fqdn into dn format for Path $linkedgpo and GPO Name:$GPODisplayName" -ForegroundColor Red
                 "Couldn't convert fqdn into dn format for Path $linkedgpo and GPO Name:$GPODisplayName" | Out-File $logfile -Append
                }
        }

    $object=[pscustomobject]@{
                Guid = $GPOguid
                DisplayName=$GPODisplayName
                LinksToGPOFQDN = $resolvedpaths
                #linksto= $LinkedTo
                LinkEnabled = $Enable
            } 
     
     $Details+=$object 
    
}
}

#Script to create GPO Links
$logfile="C:\temp\gpolink_log.txt"
Get-Date | Out-File $logfile -Append

foreach($detail in $details)

{
    
        foreach($link in $detail.LinksToGPOFQDN)
            {

              Try
                  {
                    
                    New-GPLink -Name $($detail.displayname) -Target $link -LinkEnabled Yes -ErrorAction stop | Out-Null
                    Write-Host "GPO Link $($detail.displayname) has been successfully linked to $link." -ForegroundColor Green
                    "GPO Link $($detail.displayname) has been successfully linked to $link." | Out-File $logfile -Append
                  }

            Catch
                {
                 Write-Host "GPO Link $($detail.displayname) couldn't linked to $link." -ForegroundColor Red
                 "GPO Link $($detail.displayname) couldn't linked to $link." | Out-File $LogFile  -Append
                 $_.exception.message| Out-File $LogFile -Append
                 Write-Host $_.exception.message
                }

            }#loop$detail.LinksToGPOFQDNclosed
 
}#firstloopclosed
