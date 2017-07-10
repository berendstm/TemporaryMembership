<#  
.SYNOPSIS  
    Enforces temporary group membership.   
.DESCRIPTION  
    Compares current group membership, AD replication metadata and a given date to enforce temporary group membership.   
.NOTES  
    File Name  : TemporaryMembership.ps1  
    Author     : Tyler Berends tyler.berends@outlook.com  
    Requires   : PowerShell V5  
.LINK  
#>
#Variables
$strgroup = "RDP_Access" #Name of gorup
$strdays = "10"  #Number of Days to Keep
$logpath = "C:\Temp\Logs"  #Path for log file
#Get domain controller
$domaincontroller = $env:LOGONSERVER -replace "\\", ""
#Group Object
$objgroup = Get-ADGroup -Identity $strgroup
#Format Date
$date = (Get-Date).AddDays( - $strdays)
$strdate = Get-Date $date -format g

#Start Transcript
$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path "$logpath\$strgroup.txt" -append

#Data arrays
$arrmembership = Get-ADGroupMember -Identity $objgroup.Name
$arrmetadata = Get-ADReplicationAttributeMetadata -Object $objgroup.DistinguishedName -Server $domaincontroller -ShowAllLinkedValues -Filter {AttributeName -eq "member"} -ErrorAction Stop

#Match membership to meta data
ForEach ($meta in $arrmetadata) {
    If (($arrmembership | select DistinguishedName -ExpandProperty DistinguishedName) -contains $meta.AttributeValue) {
        $dn = $meta.AttributeValue
        Write-Output "Meta Data Match: $dn" 
        #Remove items added before $strdate
        If ($meta.FirstOriginatingCreateTime -lt $strdate) {
            Write-Output "$dn will be removed from group."
            Remove-ADGroupMember -Identity $objgroup.Name -Members "$dn" -Confirm:$false | Out-String
                
        }
    }
    ELSE {
        Write-Output "No meta data/membership match.  Skipping."
    }
}
#Stop Transcript
Stop-Transcript