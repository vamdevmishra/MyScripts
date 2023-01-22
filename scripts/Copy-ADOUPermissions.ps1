<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
   first take the permission dump from source domain using below command
   (Get-Acl -Path "AD:OU=TestOU,DC=Contoso,DC=com").access  | Export-Csv C:\Temp\OUACLs.csv -NoTypeInformation and then pass this file as a input in target domain.
.EXAMPLE
#For same domain 
Copy-ADOUPermissions -SourceOUDN "OU=testou,DC=contoso,DC=com"  -TargetOUDN "OU=gpuri,DC=contoso,DC=com" -IdentityReference 'contoso\cisspuser' -RemoteDomainorForest $false
.EXAMPLE
#to update permission through csv
Copy-ADOUPermissions -TargetOUDN "OU=gpuri,DC=contoso,DC=com" -IdentityReference 'Contoso\cisspuser' -csvfile  C:\Temp\OUACLs.csv -InputthroughCSV $true
.EXAMPLE
  Copy-ADOUPermissions -SourceOUName testou -TargetOUDN "OU=West Zone,DC=fabrikam,DC=com"  -RemoteDomainorForest $true -IdentityReference 'contoso\cisspuser' -TargetDomain 'fabrikam.com'
#>
function Copy-ADOUPermissions
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $SourceOUDN,
        [Parameter(Mandatory=$true,        
                   Position=1)]
        $TargetOUDN,

        [Parameter(Mandatory=$false,        
                   Position=2)]
        $TargetDomain,

        [Parameter(Mandatory=$false,        
                   Position=3)]
        $IdentityReference,

        [Parameter(Mandatory=$false,        
                   Position=4)]
        [bool]$RemoteDomainorForest,

        [Parameter(Mandatory=$false,        
                   Position=5)]
        [bool]$InputthroughCSV,

        [Parameter(Mandatory=$false,        
                   Position=6)]
        $csvfile

    )

    Begin
        {
         #Declaring Initial Variables
         $ErrorActionPreference="Stop"
         $timestamp=$(get-date -f dd-MM-yyHHmmss)  
         $wellKnownSIDs = @{
            'S-1-0' = 'Null Authority'
            'S-1-0-0' = 'Nobody'
            'S-1-1' = 'World Authority'
            'S-1-1-0' = 'Everyone'
            'S-1-2' = 'Local Authority'
            'S-1-2-0' = 'Local'
            'S-1-2-1' = 'Console Logon'
            'S-1-3' = 'Creator Authority'
            'S-1-3-0' = 'Creator Owner'
            'S-1-3-1' = 'Creator Group'
            'S-1-3-2' = 'Creator Owner Server'
            'S-1-3-3' = 'Creator Group Server'
            'S-1-3-4' = 'Owner Rights'
            'S-1-5-80-0' = 'All Services'
            'S-1-4' = 'Non-unique Authority'
            'S-1-5' = 'NT Authority'
            'S-1-5-1' = 'Dialup'
            'S-1-5-2' = 'Network'
            'S-1-5-3' = 'Batch'
            'S-1-5-4' = 'Interactive'
            'S-1-5-6' = 'Service'
            'S-1-5-7' = 'Anonymous'
            'S-1-5-8' = 'Proxy'
            'S-1-5-9' = 'Enterprise Domain Controllers'
            'S-1-5-10' = 'Principal Self'
            'S-1-5-11' = 'Authenticated Users'
            'S-1-5-12' = 'Restricted Code'
            'S-1-5-13' = 'Terminal Server Users'
            'S-1-5-14' = 'Remote Interactive Logon'
            'S-1-5-15' = 'This Organization'
            'S-1-5-17' = 'This Organization'
            'S-1-5-18' = 'Local System'
            'S-1-5-19' = 'NT Authority'
            'S-1-5-20' = 'NT Authority'
            'S-1-5-21-500' = 'Administrator'
            'S-1-5-21-501' = 'Guest'
            'S-1-5-21-502' = 'KRBTGT'
            'S-1-5-21-512' = 'Domain Admins'
            'S-1-5-21-513' = 'Domain Users'
            'S-1-5-21-514' = 'Domain Guests'
            'S-1-5-21-515' = 'Domain Computers'
            'S-1-5-21-516' = 'Domain Controllers'
            'S-1-5-21-517' = 'Cert Publishers'            
            'S-1-5-21-518' = 'Schema Admins'
            'S-1-5-21-519' = 'Enterprise Admins'
            'S-1-5-21-520' = 'Group Policy Creator Owners'
            'S-1-5-21-522' = 'Cloneable Domain Controllers'
            'S-1-5-21-526' = 'Key Admins'
            'S-1-5-21-527' = 'Enterprise Key Admins'
            'S-1-5-21-553' = 'RAS and IAS Servers'
            'S-1-5-21-571' = 'Allowed RODC Password Replication Group'
            'S-1-5-21-572' = 'Denied RODC Password Replication Group'
            'S-1-5-32-544' = 'Administrators'
            'S-1-5-32-545' = 'Users'
            'S-1-5-32-546' = 'Guests'
            'S-1-5-32-547' = 'Power Users'
            'S-1-5-32-548' = 'Account Operators'
            'S-1-5-32-549' = 'Server Operators'
            'S-1-5-32-550' = 'Print Operators'
            'S-1-5-32-551' = 'Backup Operators'
            'S-1-5-32-552' = 'Replicators'
            'S-1-5-64-10' = 'NTLM Authentication'
            'S-1-5-64-14' = 'SChannel Authentication'
            'S-1-5-64-21' = 'Digest Authority'
            'S-1-5-80' = 'NT Service'
            'S-1-5-83-0' = 'NT VIRTUAL MACHINE\Virtual Machines'
            'S-1-16-0' = 'Untrusted Mandatory Level'
            'S-1-16-4096' = 'Low Mandatory Level'
            'S-1-16-8192' = 'Medium Mandatory Level'
            'S-1-16-8448' = 'Medium Plus Mandatory Level'
            'S-1-16-12288' = 'High Mandatory Level'
            'S-1-16-16384' = 'System Mandatory Level'
            'S-1-16-20480' = 'Protected Process Mandatory Level'
            'S-1-16-28672' = 'Secure Process Mandatory Level'
            'S-1-5-32-554' = 'BUILTIN\Pre-Windows 2000 Compatible Access'
            'S-1-5-32-555' = 'BUILTIN\Remote Desktop Users'
            'S-1-5-32-556' = 'BUILTIN\Network Configuration Operators'
            'S-1-5-32-557' = 'BUILTIN\Incoming Forest Trust Builders'
            'S-1-5-32-558' = 'BUILTIN\Performance Monitor Users'
            'S-1-5-32-559' = 'BUILTIN\Performance Log Users'
            'S-1-5-32-560' = 'BUILTIN\Windows Authorization Access Group'
            'S-1-5-32-561' = 'BUILTIN\Terminal Server License Servers'
            'S-1-5-32-562' = 'BUILTIN\Distributed COM Users'
            'S-1-5-32-569' = 'BUILTIN\Cryptographic Operators'
            'S-1-5-32-573' = 'BUILTIN\Event Log Readers'
            'S-1-5-32-574' = 'BUILTIN\Certificate Service DCOM Access'
            'S-1-5-32-575' = 'BUILTIN\RDS Remote Access Servers'
            'S-1-5-32-576' = 'BUILTIN\RDS Endpoint Servers'
            'S-1-5-32-577' = 'BUILTIN\RDS Management Servers'
            'S-1-5-32-578' = 'BUILTIN\Hyper-V Administrators'
            'S-1-5-32-579' = 'BUILTIN\Access Control Assistance Operators'
            'S-1-5-32-580' = 'BUILTIN\Remote Management Users'
        }
         Write-Host "OU Delegation script has been started" -ForegroundColor Green
        }
    Process
        {
         
         
          if($RemoteDomainorForest)
          {
          #Write-Host "enter the credential in domain\useracount forest" 
          $cred=$fabrikamcred
          #$cred=Get-Credential 

          $SourceOUDNPath = (Get-ADOrganizationalUnit -Filter {Distinguishedname -eq $SourceOUDN}).Distinguishedname

          $targetOUDNPath = (Get-ADOrganizationalUnit -Filter {Distinguishedname -eq $TargetOUDN} -Server $targetdomain).Distinguishedname
          #New-PSDrive -Name AD2 -PSProvider ActiveDirectory -Server $TargetDomain -root "//RootDSE/"  | Out-Null
          $targetouacls=Invoke-Command -ComputerName 'fabrikamdc01.fabrikam.com' -Credential $cred -ArgumentList $targetOUDNPath `
          -ScriptBlock {Import-module activedirectory; Get-Acl -Path "AD:$($targetOUDNPath)"}
          #Write-Host "target OU acls to assign is as below before making the permission" -ForegroundColor Green
          #$targetouacls.Access | ft 
          
      if($SourceOUDNPath -and $targetOUDNPath)
        {

          if($IdentityReference)
              {
              $sourceOUacls= ((Get-ACL -Path "AD:$($SourceOUDNPath)" -ErrorAction Stop)).Access `
              | ?{$_.identityreference -eq $IdentityReference}

              $replaceidentity=$identityreference.Replace("contoso","fabrikam")
              $identity=New-Object System.Security.Principal.NTAccount($replaceidentity)
             # Write-Host "identity to assign permission is $identity" -ForegroundColor Yellow
              foreach($acl in $sourceOUacls)
                {
       
                    $assignpermissionguid= [GUID] $acl.ObjectType.Guid
                    $customacl= New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
                    ($Identity ,$acl.ActiveDirectoryRights, $acl.AccessControlType, $assignpermissionguid,$acl.InheritanceType)
                    #Write-Host "custom acls as below" -ForegroundColor Green
                    #$customacl
                    $targetouacls.AddAccessRule($customacl)
                    #$targetouacls

               }
               #Write-Host "target OU acls to assign is as below after making the permission" -ForegroundColor Green
               #$targetouacls.Access | ?{$_.identityreference -eq "fabrikam\cisspuser"}  | ft

                    Try
                       {
                         #Write-Host $targetOUDNPath -ForegroundColor Green
                         $targetouacls.Access | ?{$_.identityreference -eq "fabrikam\cisspuser"}  | select identityreference, activedirectoryrights | ft
                         #$targetouacls.Access | ?{$_.identityreference
                         Invoke-Command -ComputerName 'fabrikamdc01.fabrikam.com' -Credential $cred  `
                          {Set-Acl -Path "OU=UNIX,DC=fabrikam,DC=com" -AclObject $using:targetouacls -Verbose -ErrorAction Stop}
                           Write-Host "permission assigned successfully" -ForegroundColor Green
                       }
                    Catch
                        {
                         Write-Host "couldn't set OU Permission" -ForegroundColor Red
                         $_.exception.message
                        }

         }#ifcloses

         else
             {
              $sourceOUacls= ((Get-ACL -Path "AD:$($SourceOUDNPath)" -ErrorAction Stop)).Access
              foreach($acl in $sourceOUacls)
                {
       
                    $assignpermissionguid= [GUID] $acl.ObjectType.Guid
                    $customacl= New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
                    ($Identity ,$acl.ActiveDirectoryRights, $acl.AccessControlType, $assignpermissionguid,$acl.InheritanceType) -ErrorAction Stop
                    $targetouacls.AddAccessRule($customacl)

               }
                    Try
                       {
                        
                         Set-Acl -Path "AD:$targetOUDNPath" -AclObject $targetouacls -ErrorAction Stop
                         Write-Host "permission assigned successfully" -ForegroundColor Green
                       }
                    Catch
                        {
                         Write-Host "couldn't set OU Permission" -ForegroundColor Red
                         $_.exception.message
                        }
         }#elsecloses
                 }#ifsourceoudn -and targetoudnpath exists check

     else
         {
          Write-Host "couldn't fetch sourceoudnpath or targetoudnpath, skipping adding custom ACLs" -ForegroundColor Red
         }

             }#ifRemoteDomainorForest

          elseif($RemoteDomainorForest -eq $false -and $InputthroughCSV -eq $false)    
          {    
          $targetOUDNPath = (Get-ADOrganizationalUnit -Filter {Distinguishedname -eq $TargetOUDN}).Distinguishedname
          $targetouacls=Get-Acl -Path "AD:$targetOUDNPath"

          $SourceOUDNPath = (Get-ADOrganizationalUnit -Filter {Distinguishedname -eq $SourceOUDN}).Distinguishedname
        
        if($SourceOUDNPath -and $targetOUDNPath)
        {
          if($IdentityReference)
              {
              $sourceOUacls= ((Get-ACL -Path "AD:$($SourceOUDNPath)" -ErrorAction Stop)).Access `
              | ?{$_.identityreference -eq $IdentityReference}

               Write-Host "total count of permissions to be added are $($sourceOUacls.count)" -ForegroundColor Green
               Write-Host "total count of permissions before adding new permissions are $(($targetouacls.Access).count)" -ForegroundColor Green

              $identity = New-Object System.Security.Principal.NTAccount($IdentityReference)
              foreach($acl in $sourceOUacls)
                {
       
                    $assignpermissionguid= [GUID] $acl.ObjectType.Guid
                    $customacl= New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
                    ($identity,$acl.ActiveDirectoryRights, $acl.AccessControlType, $assignpermissionguid,$acl.InheritanceType, $acl.inheritedObjectType)
                    $targetouacls.AddAccessRule($customacl)

                    #Write-Host "target OU acls to assign is as below" -ForegroundColor Green
                    #$targetouacls

               }
                    Try
                       {
                         #$targetouacls.Access  | select identityreference, activedirectoryrights | ft
                         Set-Acl -Path "AD:$targetOUDNPath" -AclObject $targetouacls -ErrorAction Stop
                         Write-Host "permission assigned successfully" -ForegroundColor Green
                       }
                    Catch
                        {
                         Write-Host "couldn't set OU Permission" -ForegroundColor Red
                         $_.exception.message
                        }

         }#IfIdentityReference

         else
             {
              $sourceOUacls= ((Get-ACL -Path "AD:$($SourceOUDNPath)" -ErrorAction Stop)).Access
              foreach($acl in $sourceOUacls)
                {
                    $Identity=New-Object System.Security.Principal.NTAccount($acl.IdentityReference)
                    $assignpermissionguid= [GUID] $acl.ObjectType.Guid
                    $customacl= New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
                    ($Identity,$acl.ActiveDirectoryRights, $acl.AccessControlType, $assignpermissionguid,$acl.InheritanceType)
                    #$customacl
                    $targetouacls.AddAccessRule($customacl)

               }
                    Try
                       {
                         Set-Acl -Path "AD:$targetOUDNPath" -AclObject $targetouacls -ErrorAction Stop
                         Write-Host "permission assigned successfully" -ForegroundColor Green
                       }
                    Catch
                        {
                         Write-Host "couldn't set OU Permission" -ForegroundColor Red
                         $_.exception.message
                        }

         }##elsennotidentityreference
         } #ifsourceoudnpath -and $targetoudnpath

         else
         {
          Write-Host "couldn't fetch sourceoudnpath or targetoudnpath, skipping adding custom ACLs" -ForegroundColor Red
         }
                         $targetouacls=Get-Acl -Path "AD:$targetOUDNPath"
                        Write-Host "total count of permissions after adding new permissions are $(($targetouacls.Access).count)" -ForegroundColor Green


         }#elsenootremotedomainorforest

          if($InputthroughCSV -and $RemoteDomainorForest -eq $false)    
          { 
          #$csvlocation=Read-Host "enter the csv fle location"
          #$csvcontent=Import-Csv $csvlocation  
          $csvcontent= import-csv $csvfile | ? {$_.identityreference -eq $IdentityReference}
          Write-Host "total permissions needs to be assigned are -> $(($csvcontent).count)" -ForegroundColor Green
          $targetOUDNPath = (Get-ADOrganizationalUnit -Filter {Distinguishedname -eq $TargetOUDN}).Distinguishedname
          $targetouacls=Get-Acl -Path "AD:$targetOUDNPath"
          Write-Host "total count of permissions before adding new permissions are $(($targetouacls.Access).count)" -ForegroundColor Green
             
        if($targetOUDNPath -and $csvcontent)
        {
          if($IdentityReference)
              {

                 $useraccount=$IdentityReference.Split("\")[1]
                 $object = New-object System.Security.Principal.NTAccount($useraccount)

              
              foreach($acl in $csvcontent)
                {

       
                    $assignpermissionguid= [GUID] $acl.ObjectType
                    $customacl= New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
                    ($object ,$acl.ActiveDirectoryRights, $acl.AccessControlType, $assignpermissionguid,$acl.InheritanceType, $acl.inheritedObjectType)
                    $targetouacls.AddAccessRule($customacl)

               }
                    Try
                       {
                         Set-Acl -Path "AD:$targetOUDNPath" -AclObject $targetouacls -ErrorAction Stop
                         Write-Host "permission assigned successfully" -ForegroundColor Green
                       }
                    Catch
                        {
                         Write-Host "couldn't set OU Permission" -ForegroundColor Red
                         $_.exception.message
                        }

          $targetouacls=Get-Acl -Path "AD:$targetOUDNPath"

          Write-Host "total count of permissions after adding new permissions are $(($targetouacls.Access).count)" -ForegroundColor Green

         }#IfIdentityReference

         else
             {
              $sourceOUacls= ((Get-ACL -Path "AD:$($SourceOUDNPath)" -ErrorAction Stop)).Access
              foreach($acl in $sourceOUacls)
                {
       
                    $assignpermissionguid= [GUID] $acl.ObjectType.Guid
                    $customacl= New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
                    ($Identity ,$acl.ActiveDirectoryRights, $acl.AccessControlType, $assignpermissionguid,$acl.InheritanceType)
                    $targetouacls.AddAccessRule($customacl)

               }
                    Try
                       {
                         Set-Acl -Path "AD:$targetOUDNPath" -AclObject $targetouacls -ErrorAction Stop
                         Write-Host "permission assigned successfully" -ForegroundColor Green
                       }
                    Catch
                        {
                         Write-Host "couldn't set OU Permission" -ForegroundColor Red
                         $_.exception.message
                        }

         }##elsennotidentityreference
         } #ifsourceoudnpath -and $targetoudnpath

         else
         {
          Write-Host "couldn't fetch sourceoudnpath or targetoudnpath, skipping adding custom ACLs" -ForegroundColor Red
         }

         }#Inputthroughcsv

        }#Processclosing

        End
        {
         Write-Host "script completed !!" -ForegroundColor Green
        }

}#functionclosing
