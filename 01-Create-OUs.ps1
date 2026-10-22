<#
  01-Create-OUs.ps1
  Run on : CRF-DC01 (PowerShell as Administrator)
  Purpose: Optional shortcut for Section 3. Builds the CobaltRidge OU structure.
           (You can also create these by hand in Active Directory Users and Computers.)
#>
Import-Module ActiveDirectory

$dn = (Get-ADDomain).DistinguishedName
New-ADOrganizationalUnit -Name "CobaltRidge" -Path $dn

$root = "OU=CobaltRidge,$dn"
"Finance","HR","IT","Computers","Groups","Disabled-Users" |
    ForEach-Object { New-ADOrganizationalUnit -Name $_ -Path $root }

# Check the result
Get-ADOrganizationalUnit -Filter * -SearchBase $root | Select-Object Name, DistinguishedName
