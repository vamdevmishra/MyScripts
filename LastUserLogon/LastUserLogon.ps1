 <#Version 2.0
     # Improvements over version 1.0
       1. Added Custom Error, Error Message in the output file
       2. Declared Variables initially as $null
       3. Added LastLogon as Type, instead of Numeric Values
       4. Added Output in format-table for single query.
.Synopsis
   This Script is used to find LastUserLogon for a computer/s.
.DESCRIPTION
   NA
.EXAMPLE
   Get-LastUserLogon -ComputerName MyComputer
.EXAMPLE
   Get-Adcomputer -Identity MyPc | Get-LastUserLogon
.EXAMPLE
   For bulk/CSV files
    Import-csv C:\temp\Input.csv | %{Get-LastUserLogon -computername $_.computername} `
   | select Time,Computer,UserLogon,LogonType,ErrorMessage,Error `
   | export-csv C:\temp\Output.csv -notypeinformation 
#>

function Get-LastUserLogon
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        #Parameters Declaration
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$True,
                   Position=0)]
                   $ComputerName,

        [Parameter(Mandatory=$False,
                   Position=1)]
                   $Domain="Fareast"
    )

    Begin
    {
    #Write-Host "Script has been started..." -ForegroundColor Green
    
    #Xpath Query to find the Security Event logs 4624 for DomainUser Accounts Only, domain specified in the runtime.
    $query = @"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">
      *[System[(EventID=4624)]] and
      *[EventData[Data[@Name='TargetDomainName'] = "$Domain"]] 
    </Select>
  </Query>
</QueryList>
"@
    }
    Process
    {   
        Write-Host "checking for computer $computername" -ForegroundColor Green 
        
        Try
            {
            #Declare the variables

             
             $UserLogon             = $null 
             $LogonType             = $null 
             $Time                  = $null
             $Error                 = $False
             $ErrorMessage          = 'NA'
             $unableMsg             = 'Unable to determine'
            
            #Running the query on the target Machine.
            $Event= Get-WinEvent -FilterXml $query -MaxEvents 1 -ComputerName $ComputerName -ErrorAction Stop `
            | Select @{ N = ‘User’; E = { $_.Properties[5].Value } }, `
            @{ N = ‘LogonType’; E = { $_.Properties[8].Value } }, TimeCreated

            #Use a switch to get the text value based on the number in $Event.LogonType
             Switch ($Event.LogonType) {
                                       2{$LogonType = 'Interactive Logon'}
                                       3{$LogonType = 'Network Logon'}
                                       4{$LogonType = 'Batch Logon'}
                                       5{$LogonType = 'Service Logon'}
                                       7{$LogonType = 'Unlock Logon'}
                                       8{$LogonType = 'NetworkClearText Logon'}
                                       9{$LogonType = 'NewCredentials Logon'}
                                       10{$LogonType = 'RemoteInteractive Logon'}
                                       11{$LogonType = 'CachedInteractive Logon'}
                                 Default {$LogonType = 'Unable to determine'}
                                       }

            #Declare the PSOjbject to hold the properties.
            $Object = New-Object PSObject -Property @{
                                                    Computer              = $ComputerName
                                                    UserLogon             = $event.User
                                                    LogonType             = $LogonType
                                                    Time                  = $event.TimeCreated
                                                    ErrorMessage          = $ErrorMessage
                                                    Error                 = $Error
                                                 }
             #Return the object created
             Return $object | select Time,Computer,UserLogon,LogonType,ErrorMessage,Error |ft
            }

        Catch {
               #Capture the exception message in the $errorMessage variable
                $errorMessage = $_.Exception.Message    
                
                #Create our custom object with the error message     
                $Object = New-Object PSObject -Property @{
                                                    Computer              = $ComputerName
                                                    UserLogon             = $unableMsg
                                                    LogonType             = $unableMsg
                                                    Time                  = $unableMsg
                                                    Error                 = $true
                                                    ErrorMessage          = $errorMessage 
                                                                   
                                                 }
              #Return the object created
              Return $object | select Time,Computer,UserLogon,LogonType,ErrorMessage,Error | ft
              Break
              }
                #Created $results Variable to hold all the objects
                $results = @()
                #Adding the objects to the Result Array
                $results += $Object
         
        }
        End
        {
         
        }
}

   #Sample Query to Run

   #Import-csv C:\temp\Input.csv | %{Get-LastUserLogon -computername $_.computername} `
   #| select Time,Computer,UserLogon,LogonType,ErrorMessage,Error `
   #| export-csv C:\temp\Output.csv -notypeinformation 