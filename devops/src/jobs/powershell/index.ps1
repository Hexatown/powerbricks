. "$PSScriptRoot\.hexatown.com.ps1"                # Load the Hexatown framework
$hexatown = Start-Hexatown  $myInvocation          # Start the framework
Read $hexatown my self | fl                        # Read my self 
Stop-Hexatown $hexatown                            # Stop the framework       