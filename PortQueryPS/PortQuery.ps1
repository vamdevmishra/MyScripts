Function Connect-TCPClient
{

[CmdletBinding()]
    [OutputType([System.Net.Sockets.TcpClient])]
    param
    (
        # Hostname or IP address of the server.
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'Hostname or IP address of server')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Server="<YourServerFQDN>",

        # Port of the server (1-65535)
        [Parameter(Mandatory   = $true,
                   HelpMessage = 'Port of the server (1-65535)')]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 65535)]
        [UInt16]
        $Port ="135"
    )

    # Create a TCP client Object
    Try 
    {
        $TcpClient = New-Object -TypeName System.Net.Sockets.TcpClient
        $TcpClient.Connect($Server, $Port)
    }
    Catch 
    {
        Throw $_
    }

    $TcpClient
}