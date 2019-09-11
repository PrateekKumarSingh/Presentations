#Test-Port -Source '127.0.0.1' -RemoteDestination 'dc1' -Port 57766
#Test-Port '127.0.0.1' 'dc1' 57766 -Protocol UDP -Iterate
#Test-Port 'localhost' 'dc2' 51753 -Protocol UDP
#Test-Port -Source $EUCAS -RemoteDestination $EUMBX -Port 135 -Iterate
#Test-Port -Source 'localhost' -RemoteDestination '127.0.0.1' -Port 135 -Iterate -protocol TCP

Function Test-Port() {

    Param
    (
        [Parameter(Position = 0)] $Source,
        [Parameter(Mandatory = $true, Position = 1)] $RemoteDestination,
        [Parameter(Mandatory = $true, Position = 2)][ValidateScript( {
      
                If ($_ -match "^[0-9]+$") {
                    $True
                }
                else {
                    Throw "A port should be a numeric value, and $_ is not a valid number"
                }
            })
        ]$Port,
        [Parameter(Position = 3)][ValidateSet('TCP', 'UDP')] $Protocol = 'TCP',
        [Switch] $Iterate
    )


    Function Telnet-Port ($RemoteDestination, $port, $Protocol) {
        foreach ($Target in $RemoteDestination) {
            Foreach ($CurrentPort in $Port) {
                If ($Protocol -eq 'TCP') {
                        
                    try {
                        If ((New-Object System.Net.Sockets.TCPClient ($Target, $currentPort) -ErrorAction SilentlyContinue).connected) {
                                
                            [PSCustomObject]@{
                                Source      = (hostname).toupper()
                                Destination = $Target.toupper()
                                Port        = $CurrentPort
                                Connected   = $true
                            }
                        }
                    }
                    catch {
                        [PSCustomObject]@{
                            Source      = (hostname).toupper()
                            Destination = $Target.toupper()
                            Port        = $CurrentPort
                            Connected   = $false
                        }
                    }            
                }
                Else {   
                                                                  
                    #Create object for connecting to port on computer   
                    $UDPClient = new-Object system.Net.Sockets.Udpclient 
                        
                    #Set a timeout on receiving message, to avoid source machine to Listen forever. 
                    $UDPClient.client.ReceiveTimeout = 5000 
                        
                    #Datagrams must be sent with Bytes, hence the text is converted into Bytes
                    $ASCII = new-object system.text.asciiencoding
                    $Bytes = $ASCII.GetBytes("Hi")
                        
                    #UDP datagram is send
                    [void]$UDPClient.Send($Bytes, $Bytes.length, $Target, $Port)  
                    $RemoteEndpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any, 0)  
                         
                    Try {
                        #Waits for a UDP response until timeout defined above
                        $RCV_Bytes = $UDPClient.Receive([ref]$RemoteEndpoint)  
                        $RCV_Data = $ASCII.GetString($RCV_Bytes) 
                        If ($RCV_Data) {
                               
                                    
                            [PSCustomObject]@{
                                Source      = (hostname).toupper()
                                Destination = $Target.toupper()
                                Port        = $CurrentPort
                                Connected   = $true
                            }
                        }
                    }
                    catch {
                        #if the UDP recieve is timed out
                        #it's infered that no response was received.
                        [PSCustomObject]@{
                            Source      = (hostname).toupper()
                            Destination = $Target.toupper()
                            Port        = $CurrentPort
                            Connected   = $false
                        }
                    }
                    Finally {
    
                        #Disposing Variables
                        $UDPClient.Close()
                        $RCV_Data = $RCV_Bytes = $null
                    }                                    
                }
    
            }
        }
    }
    #If $source is a local name, invoke command is not required and we can test port, withhout credentials
    If ($Source -like "127.*" -or $source -like "*$(hostname)*" -or $Source -like 'localhost') {
        Do {
            Telnet-Port $RemoteDestination $Port $Protocol;
            Start-Sleep -Seconds 1   #Initiate sleep to slow down Continous telnet

        }While ($Iterate)
       
    }
    Else {
        #Prompt for credentials when Source is not the local machine.     
        $creds = Get-Credential

        Do {
            Foreach ($Src in $Source) {          
                Invoke-command -ComputerName $Src -Credential $creds -ScriptBlock ${Function:Telnet-Port} -ArgumentList $RemoteDestination, $port, $Protocol                                            
            }

            #Initiate sleep to slow down Continous telnet
            Start-Sleep -Seconds 1
        }While ($Iterate)
       
    }

}
  
