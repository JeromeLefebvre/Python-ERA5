
<# Todo

#>
#　リソースグループ名
$RegionName = "australiaeast"
$ResourceGroupName = "TestResourceGroup"

function New-Resource-Group {
    param (
        [string] $ResourceGroupName,
        [string] $RegionName
    )
    Write-Host "Creating a Resource Group called $($ResourceGroupName), https://portal.azure.com/#view/HubsExtension/BrowseResourceGroups"
    $ressourceGroup = @{
        Name = $ResourceGroupName
        Location = $RegionName
    }
    New-AzResourceGroup @ressourceGroup
}

Connect-AzAccount
New-Resource-Group -ResourceGroupName $ResourceGroupName -RegionName $RegionName

