# devops

This PowerBrick demonstrate how you can get access to Azure using delegated permission to Office Graph.


# Requirments

2 Environmental variables has to be set to support one-liner connect

```
PWD=************
USER=***********

```

PWD is user password to the VM
USER is the username

# Use Cases
The PowerBrick supports the following use cases

## One-liner for starting and Connecting to VM
Start VM, create RDP file and Windows Credentials

```powershell
hexa run devops connect VirtualMachineName
# Save the command as a dot Command
hexa . myvm run devops connect VirtualMachineName
# Execute saved command
hexa .myvm
```

## Stop VM

```powershell
hexa run devops stop VirtualMachineName
```

## Start VM
```powershell
hexa run devops start VirtualMachineName
```

## List VM's
```powershell
hexa run devops vms
```

