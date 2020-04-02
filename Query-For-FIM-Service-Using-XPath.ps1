# Abstract: This PoSH Script Exports Objects From The FIM Based Upon An XPath Definition, Converts It To PSObjects And Displays On Screen And Optionally Exports To CSV
# Written by: Jorge de Almeida Pinto [MVP-DS]
# Blog: http://jorgequestforknowledge.wordpress.com/
#
# 2015-03-30: Initial version of the script
#
# Additional Information
# * http://www.integrationtrench.com/2011/07/convert-fim-exportobject-to-powershell.html
# * http://www.integrationtrench.com/2011/09/cant-use-xpath-contains-function-to.html

# Example Syntaxes:
# * <PoSH Script File> -xPath "/Person[AccountName='JohnDoe']" -baseonly
# * <PoSH Script File> -xPath "/Person[AccountName='JohnDoe']" -baseonly -attributelist ObjectID,AccountName
# * <PoSH Script File> -xPath "/Person[AccountName='JohnDoe']" -baseonly -exporttocsv -csvfilepath D:\TEMP\TEST.CSV
# * <PoSH Script File> -xPath "/Person[AccountName='JohnDoe']" -baseonly -attributelist ObjectID,AccountName -exporttocsv -csvfilepath D:\TEMP\TEST.CSV

Param (	
	# XPath Definition As Accepted By The FIM Service (e.g. "/Person[Account = 'JohnDoe']")
	[Parameter(Mandatory=$true)]
	[string]$xPath,
	# Comma-Separated List Of Attributes To Display/Export. When Nothing is Specified All Attributes Are Displayed/Exported
	[Parameter(Mandatory=$false)]
	[string[]]$attributelist,
	# The Full Path To The CSV File When Exporting To A CSV
	[Parameter(Mandatory=$false)]
	[string]$csvfilepath,
	# Export Only Based Objects (Recommended), Otherwise Also Export All Referred Objects
	[Parameter(Mandatory=$false)]
	[switch]$baseonly,
	# Also Export To CSV
	[Parameter(Mandatory=$false)]
	[switch]$exporttocsv
) 
	
Clear-Host
Write-Host "                            ****************************************************" -ForeGroundColor Yellow
Write-Host "                            **         Jorge de Almeida Pinto [MVP-DS]        **" -ForeGroundColor Yellow
Write-Host "                            **      BLOG: 'Jorge's Quest For Knowledge'       **" -ForeGroundColor Yellow
Write-Host "                            **  http://jorgequestforknowledge.wordpress.com/  **" -ForeGroundColor Yellow
Write-Host "                            **                   March 2015                   **" -ForeGroundColor Yellow
Write-Host "                            ****************************************************" -ForeGroundColor Yellow

# MSFT PowerShell CMDlets For FIM 2010 R2
[array] $SnapInListToLoad = "FIMAutomation"
foreach ($SnapIn In $SnapInListToLoad) {
	If(@(Get-PSSnapin | Where-Object {$_.Name -eq $SnapIn} ).count -eq 0) {
		If(@(Get-PSSnapin -Registered | Where-Object {$_.Name -eq $SnapIn} ).count -ne 0) {
			Add-PSSnapin $SnapIn
			Write-Host ""
			Write-Host "Snap-In '$SnapIn' has been loaded..." -ForeGroundColor Green
			Write-Host ""
		} Else {
			Write-Host ""
			Write-Host "Snap-In '$SnapIn' is not available to load..." -ForeGroundColor Red
			Write-Host ""
		}
	} Else {
		Write-Host ""
		Write-Host "Snap-In '$SnapIn' already loaded..." -ForeGroundColor Yellow
		Write-Host ""	
	}
}

# Taken From http://www.integrationtrench.com/2011/07/convert-fim-exportobject-to-powershell.html
Function Convert-FimExportToPSObject { 
    Param ( 
        [parameter(Mandatory=$true, ValueFromPipeline = $true)] 
        [Microsoft.ResourceManagement.Automation.ObjectModel.ExportObject] 
        $ExportObject 
    )
	Process {         
        $psObject = New-Object PSObject 
        $ExportObject.ResourceManagementObject.ResourceManagementAttributes | %{ 
            If ($_.Value -ne $null) { 
                $value = $_.Value 
            } Elseif ($_.Values -ne $null) { 
                $value = $_.Values 
            } Else { 
                $value = $null 
            } 
            $psObject | Add-Member -MemberType NoteProperty -Name $_.AttributeName -Value $value 
        } 
        Write-Output $psObject 
    } 
}

# If The BaseOnly Parameter Has Been Specified Then Only Export The Base Resources As Defined By The XPath Definition
# Otherwise ALSO Export Referred Objects In Linked Attributes
If ($baseonly) {
	$ObjectsInFIM = Export-FIMConfig -CustomConfig $xPath -OnlyBaseResources
} Else {
	$ObjectsInFIM = Export-FIMConfig -CustomConfig $xPath
}

# If Additional Filtering Is Required Which Is Not Possible Through The Xpath Then Use:
# http://www.integrationtrench.com/2011/09/cant-use-xpath-contains-function-to.html
# Example: $ObjectsInFIM | Convert-FimExportToPSObject | ?{$_.Filter -like "*myAttribute*"}
# Example: $ObjectsInFIM | Convert-FimExportToPSObject | ?{$_.XOML -like "*myValue*"}
# !!! ==> ADJUST THE POWERSHELL MANUALLY TO BE ABLE TO USE THIS <== !!!

# If The ExportCsv Parameter Has Been Specified Then ALSO Export To The CSV File Defined
# Otherwise Just Show Information On Screen
If ($exporttocsv) {
	$ObjectsInFIM | Convert-FimExportToPSObject | Select $attributelist | Export-CSV $csvfilepath -NoTypeInformation
}
$ObjectsInFIM | Convert-FimExportToPSObject | FT $attributelist -Autosize

# Count The Number Of Objects
$NumberOfObjectsInFIM = ($ObjectsInFIM | Measure-Object).Count
Write-Host "Number Of Objects......: $NumberOfObjectsInFIM"
Write-Host ""