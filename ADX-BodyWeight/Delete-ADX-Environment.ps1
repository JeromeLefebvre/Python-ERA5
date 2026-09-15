
<#
TODO
* make delete async so that I can get my prompt back faster
#>
$ResourceGroupName = "TestResourceGroup"

$continue = Read-Host "Don't Delete resources? (n)"

if ($continue -eq "n") {
    exit
}

Write-Host "**Deleting resources group**"

Write-Host "Deleting a Resource Group named $ResourceGroupName"
Get-AzResourceGroup -Name $ResourceGroupName| Remove-AzResourceGroup -Force

#Remove-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $rgName
#https://learn.microsoft.com/en-us/powershell/module/az.network/remove-azpublicipaddress?view=azps-9.6.0