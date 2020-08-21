<# Version 1.0
.DESCRIPTION
	This Breakfix Powershell Script is to Fix Windows Update issue in which client machine is stuck at 0 Percent Windows Update 
    This Function stops the Windows Update and BITS Service, Deletes the QMGR and software distribution Folders and then Restart the Services.
    #>

function Fix-WindowsUpdate {

        # Ref: http://msdn.microsoft.com/en-us/library/system.diagnostics.eventlog.sourceexists(v=vs.110).aspx
        # Check if Source exists

        If ([System.Diagnostics.EventLog]::SourceExists("Breakfix-WindowsUpdate"))
        {
        Write-EventLog -LogName Application -Source "Breakfix-WindowsUpdate" -EventId "5000" -Message "Breakfix-WindowsUpdate Source Exists, Skipping creating New Source Entry in Events" -EntryType Information
        }
        else
        {
             Try {
                  New-EventLog -source Breakfix-WindowsUpdate -LogName Application -ErrorAction Stop
                 }
             Catch {
                    #IT should not hit Catch as Eventlog Gets created generally without any failure, so leaving it blank.
                   }
        }


Try
    {
    Stop-Service -Name wuauserv -Force
    Stop-Service -Name BITS -Force
    
    Write-EventLog -LogName Application -Source "Breakfix-WindowsUpdate" -EventId "5001" -Message "Successfully stopped windows update services" -EntryType Information
            
            #Deletes the contents of QMGR Data files.
            Try
                {
                
                Remove-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat"  -Force -ErrorAction Stop
                Write-EventLog -LogName Application -Source "Breakfix-WindowsUpdate" -EventId "5003" -Message "The Contents of QMGR Folder have been removed successfully" -EntryType Information
                }

            Catch
                {
                 Write-EventLog -LogName Application -Source "Breakfix-WindowsUpdate" -EventId "5004" -Message "The Contents of QMGR Folder Couldn't be removed, $_.exception.message " -EntryType Warning
                }
       
           #Deletes the contents of windows software distribution.
           Try
                 {
                  Get-ChildItem "C:\Windows\SoftwareDistribution\*" -Recurse -Force  -ErrorAction SilentlyContinue | `
                  Remove-Item -Force -recurse -ErrorAction Stop
                  Write-EventLog -LogName Application -Source  "Breakfix-WindowsUpdate" -EventId "5005" -Message "The Contents of Windows SoftwareDistribution Folder have been removed successfully" -EntryType Information
                 }
          Catch
                 {
                  Write-EventLog -LogName Application -Source  "Breakfix-WindowsUpdate" -EventId "5006" -Message "The Contents of Windows SoftwareDistribution Folder couldn't be removed, $_.exception.message" -EntryType Warning
                 }
 
}
    Catch 
    {
    Write-EventLog -LogName Application -Source "Breakfix-WindowsUpdate" -EventId "5002" -Message "Could not stop windows update services, skipping deleting Windows Updates Folders, $_.exception.message" -EntryType Warning
    }

Try 
{
    Start-Service -Name wuauserv 
    Start-Service -Name BITS 
    
    Write-EventLog -LogName Application -Source "Breakfix-WindowsUpdate" -EventId "5007" -Message "Successfully started windows update services" -EntryType Information
    
    #Check for new Windows Updates..
    
    Invoke-Command -scriptblock {usoclient.exe startscan}

    Write-EventLog -LogName Application -Source "Breakfix-WindowsUpdate" -EventId "5008" -Message "Initiated Windows update check, Script completed" -EntryType Information
}

Catch
{
 Write-EventLog -LogName Application -Source "Breakfix-WindowsUpdate" -EventId "5009" -Message "Couldn't start windows update services, $_.exception.message" -EntryType Warning
}
}