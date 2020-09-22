<# Version 1.0
.DESCRIPTION
	This Function is to find AD User Info like expired, active etc.
. Example 
  Get-UserReport -Identity gpuri | ft
. Example 
  vamishr | Get-UserReport -Identity vamishr
. Example
  'vamishr', 'YASH' | Get-UserReport  -verbose | ft
. Example
  Import-csv c:\temp\users.csv | % {Get-UserReport -Identity $_.identity}
. Example
  Get-Content c:\temp\users.txt | Get-UserReport | export-csv C:\temp\Report.csv -notypeinformation
#>

Function Get-UserReport
{

[CmdletBinding()]
param(
    [parameter(Mandatory=$true,
    HelpMessage="Provide SamAccountName of the user",
    ValueFromPipelineByPropertyName=$true,
    ValueFromPipeline=$true)]
    $Identity
)
Begin {Write-Host "script has been started" -ForegroundColor Green}
process 
{
Write-Host "Checking AD Object $Identity" -ForegroundColor Green
Try 
    {
    Get-ADUser -Identity $Identity -Properties Samaccountname, displayname, enabled, LastLogonTimeStamp, passwordlastset, passwordneverexpires, "msDS-UserPasswordExpiryTimeComputed" -ErrorAction Stop |` 
    Select Samaccountname, Displayname,  Enabled , Passwordlastset, Passwordneverexpires, @{Name="LastLogon"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}}, @{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
    }
Catch 
    {
     Write-Host "Unable to Query User $Identity, not found" -ForegroundColor Red 
     $NoUser="User not Found in AD"
     $catchuser=New-Object -TypeName Microsoft.ActiveDirectory.Management.ADUser
     Add-Member -NotePropertyName "SamAccountName" -NotePropertyValue "$Identity" -InputObject $catchuser -Force
     Add-Member -NotePropertyName "DisplayName"    -NotePropertyValue "$NoUser" -InputObject $catchuser -Force
     Add-Member -NotePropertyName "DisplayName"     -NotePropertyValue "$NoUser" -InputObject $catchuser -Force
     Add-Member -NotePropertyName "Enabled"         -NotePropertyValue "$NoUser" -InputObject $catchuser -Force
     Add-Member -NotePropertyName "Passwordlastset" -NotePropertyValue "$NoUser" -InputObject $catchuser -Force
     Add-Member -NotePropertyName "Passwordneverexpires" -NotePropertyValue "$NoUser" -InputObject $catchuser -Force
     Add-Member -NotePropertyName "LastLogon" -NotePropertyValue "$NoUser" -InputObject $catchuser -Force
     Add-Member -NotePropertyName "ExpiryDate" -NotePropertyValue "$NoUser" -InputObject $catchuser -Force
     $catchuser
    }

}
#End {Write-Host "script has been completed" -ForegroundColor Yellow}
}
