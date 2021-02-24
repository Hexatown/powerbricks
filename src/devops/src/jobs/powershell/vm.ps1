<#
Copyright (c) Niels Gregers Johansen.

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#>


param( $cmd, $vm)

. "$PSScriptRoot\.hexatown.com.ps1"                # Load the Hexatown framework

$scope = "https%3A%2F%2Fmanagement.core.windows.net%2F%2Fuser_impersonation"
$hexatown = Start-Hexatown  $myInvocation $scope        # Start the framework
$apihost = "https://management.azure.com"
$apiversion = "2020-06-01"

<#
.SYNOPSIS
Iterate over all subscriptions 

.DESCRIPTION
Long description

.PARAMETER ScriptBlock
Will be called for each found machine - current machine can be found in $machine
{

}

.EXAMPLE

FindVM {
    write-host $machine.name $machine.location -NoNewline
    write-host " "  $public.properties.ipAddress -ForegroundColor Green

    if ($machine.name -eq $myVM) {
        write-host "*** MATCHED ***" -ForegroundColor Green
            
        $case = $cmd.ToUpper()
        switch ($x)
        {
            'CONNECT' {
                 $cmdkey = "cmdkey /generic:""$($public.properties.ipAddress)"" /user:""$($ENV:USER)"" /pass:""$($ENV:PWD)"""
                 $mstsc = "mstsc /v:$($public.properties.ipAddress):3389 /span "

                 Invoke-Expression $cmdkey 
                 Invoke-Expression $mstsc
            }
            'START' {
                 Start-Hexatown-VM $machine  
                }
            'STOP' {
                Stop-Hexatown-VM $machine
            }
            Default {
                write-host "Unknown command" -ForegroundColor Yellow
            }
        }
       
    }
}


.NOTES

#>
$apihost = "https://management.azure.com"

function GetMachineInfo($machine,$ScriptBlock){
    # https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines/get#uri-parameters
    $about = GraphAPI $hexatown GET "$apihost/$($machine.id)?api-version=$apiversion&expand=instanceView"
    $instanceView = GraphAPI $hexatown GET "$apihost/$($machine.id)/instanceView?api-version=$apiversion&expand=instanceView"
                       
    foreach ($networkInterface in $about.properties.networkProfile.networkInterfaces) {
        $network = GraphAPI $hexatown GET "$apihost/$($networkInterface.id)?api-version=$apiversion"
        $public = GraphAPI $hexatown GET "$apihost/$($network.properties.ipConfigurations[0].properties.publicIPAddress.id)?api-version=$apiversion"
        if ($null -ne $ScriptBlock) {
            Invoke-Command -ScriptBlock $ScriptBlock
        }
    }  
    return $about,$instanceView,$network,$public
}

function FindVM($ScriptBlock) {
    
    $subscriptions = GraphAPIAll $hexatown GET "$apihost/subscriptions?api-version=$apiversion"
    foreach ($subscription in $subscriptions) {
        $resourceGroups = GraphAPIAll $hexatown GET "$apihost/$($subscription.id)/resourceGroups?api-version=$apiversion"
        foreach ($resourceGroup in $resourceGroups) {
            $url = "$apihost/$($resourceGroup.id)/providers/Microsoft.Compute/virtualMachines?api-version=$apiversion"
            $machines = GraphAPIAll $hexatown GET $url 
            foreach ($machine in $machines) {
                GetMachineInfo $machine $ScriptBlock | Out-Null
                
            }
        }
    }
}


function Stop-Hexatown-VM($machine) {
    # https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines/deallocate
    write-host "Shutting down VM $($machine.name)"
    GraphAPIAll $hexatown POST "$apihost/$($machine.id)/deallocate?api-version=$apiversion"
}

function Start-Hexatown-VM($machine) {
    write-host "Starting VM $($machine.name)"
    GraphAPIAll $hexatown POST "$apihost/$($machine.id)/start?api-version=$apiversion"
}

function Connect-Hexatown-VM($machine,$public,$instanceView){
                $loop = $true
                $status = $instanceView.statuses | where {$_.code -eq "PowerState/deallocated"}
                if ($null -ne $status){
                do
                {
                    write-host "Machine is not running, starting and waiting for 60 seconds" -ForegroundColor Yellow
                    Start-Hexatown-VM $machine
                    Start-Sleep -Seconds 60
                    $machineInfo = GetMachineInfo $machine
                    $public = $machineInfo[3]
                    $loop = $false
    
                }
                until ($loop -eq $false)
                }
                
                write-host "Connecting ..." -ForegroundColor Green

                $cmdkey = "cmdkey /generic:""$($public.properties.ipAddress)"" /user:""$($ENV:USER)"" /pass:""$($ENV:PWD)"""
                $mstsc = "mstsc /v:$($public.properties.ipAddress):3389 /span "
                Invoke-Expression $cmdkey 
                # Invoke-Expression $mstsc

$desktopPath = ([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)) 
$rdpfileName = Join-Path $desktopPath "$myVM.rdp"
$rdpfile = @"
full address:s:$($public.properties.ipAddress):3389
prompt for credentials:i:0
administrative session:i:1
screen mode id:i:2
use multimon:i:1
desktopwidth:i:800
desktopheight:i:600
session bpp:i:32
winposstr:s:0,3,0,0,800,600
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
audiomode:i:0
redirectprinters:i:1
redirectcomports:i:0
redirectsmartcards:i:1
redirectclipboard:i:1
redirectposdevices:i:0
drivestoredirect:s:
autoreconnection enabled:i:1
authentication level:i:2
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewayhostname:s:
gatewayusagemethod:i:4
gatewaycredentialssource:i:4
gatewayprofileusagemethod:i:0
promptcredentialonce:i:0
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:

"@

out-file -InputObject $rdpfile -FilePath $rdpfileName

Invoke-Expression "mstsc '$rdpfileName'"

}

if ($null -eq $ENV:PWD) {
    Write-Host "You need to share the password in ENV:PWD for getting access to the remote desktop" -ForegroundColor Yellow
    Write-Error "Stopping"
    exit
}

if ($null -eq $ENV:USER) {
    Write-Host "You need to share the username in ENV:USER for getting access to the remote desktop" -ForegroundColor Yellow
    Write-Error "Stopping"
    exit
}

if ($null -eq $ENV:VM -and $null -eq $vm ) {
    Write-Host "You need to share the virtual machine name in ENV:VM or in parameter `$vm for getting access to the remote desktop" -ForegroundColor Yellow
    Write-Error "Stopping"
    exit
}

$myVM = $ENV:VM
if ($null -ne $vm) {
    $myVM = $vm
}


write-host "Reading all machines you have access to in Azure"
FindVM {
    write-host $machine.name $machine.location -NoNewline
    write-host " "  $public.properties.ipAddress -ForegroundColor Green

    if ($machine.name -eq $myVM) {
        
            
        $case = $cmd.ToUpper()
        switch ($case) {
            'CONNECT' {
                Connect-Hexatown-VM $machine $public $instanceView
            }
            'START' {
                Start-Hexatown-VM $machine  
            }
            'STOP' {
                Stop-Hexatown-VM $machine
            }
            Default {
                write-host "Unknown command" -ForegroundColor Yellow
            }
        }
       
    }
}


Stop-Hexatown $hexatown                            # Stop the framework       