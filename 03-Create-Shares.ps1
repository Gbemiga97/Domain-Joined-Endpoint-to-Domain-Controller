<#
  03-Create-Shares.ps1
  Run on : CRF-DC01 (PowerShell as Administrator), AFTER the groups exist
  Purpose: Optional shortcut for Section 5. Creates C:\Shares\Finance and C:\Shares\HR,
           sets folder (NTFS) permissions using groups, and shares both folders.
  NOTE   : Hosting shares on a domain controller is a lab shortcut. A real company
           would use a separate file server.
#>
$root = "C:\Shares"

$shares = @{
    "Finance" = @{ Modify = "FIN-Staff"; Read = "FIN-ReadOnly" }
    "HR"      = @{ Modify = "HR-Staff";  Read = $null }
}

foreach ($name in $shares.Keys) {
    $path = Join-Path $root $name
    New-Item -ItemType Directory -Path $path -Force | Out-Null

    # Folder (NTFS) permissions: remove inheritance, then grant ONLY the groups we want
    $icaclsArgs = @($path, "/inheritance:r", "/grant",
        "BUILTIN\Administrators:(OI)(CI)F",
        "NT AUTHORITY\SYSTEM:(OI)(CI)F",
        "COBALTRIDGE\$($shares[$name].Modify):(OI)(CI)M")
    if ($shares[$name].Read) { $icaclsArgs += "COBALTRIDGE\$($shares[$name].Read):(OI)(CI)RX" }
    icacls @icaclsArgs | Out-Null

    # Share the folder (the NTFS permissions above do the real restricting)
    New-SmbShare -Name $name -Path $path -ChangeAccess "NT AUTHORITY\Authenticated Users" -FullAccess "BUILTIN\Administrators" | Out-Null
}

Get-SmbShare | Where-Object Name -in "Finance","HR" | Select-Object Name, Path
