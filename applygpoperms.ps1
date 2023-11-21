$perm = import-csv C:\Temp\gpoperm.csv
$perm | %{Set-GPPermissions -Name $_.gpoName -TargetName $_.trustee -TargetType $_.trusteetype -PermissionLevel $_.Permission}
