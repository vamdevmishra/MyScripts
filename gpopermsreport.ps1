$report = @()
$allgpos=Get-GPO -All
foreach($gpo in $allgpos)
 {
  
  $gpopermissions=Get-GPPermissions -Guid $gpo.id -All

  #togetthegpopermissionseperately
    $gpoperms=@()
    foreach($gpopermission in $gpopermissions)
    {
     if($gpopermission.Trustee.sidtype -eq "WellKnownGroup") {$TrusteeType="Group"} else {$TrusteeType=$gpopermission.Trustee.sidtype}
      $object = [PSCustomObject]@{
        GPOName = $gpo.DisplayName
        Trustee = $gpopermission.Trustee.Name
        TrusteeType=$TrusteeType
        Permission=$gpopermission.Permission
        Inherited=$gpopermission.Inherited
        }

        $gpoperms+=$object
    }

  $report+=$gpoperms

 }
 
 $report | Export-Csv -NoTypeInformation gpoperm.csv
