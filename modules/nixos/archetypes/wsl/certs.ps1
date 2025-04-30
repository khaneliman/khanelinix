#

$StoreToDir = "all-certificates"
$CertExtension = "pem" # use "crt" for usage on windows systems
$InsertLineBreaks=1

If (Test-Path $StoreToDir) {
    $path = "{0}\*" -f $StoreToDir
    Remove-Item $StoreToDir -Recurse -Force
}
New-Item $StoreToDir -ItemType directory

# If you want to filter by Cert Usage (ex. for language independent match proividing server authentificaten Certs: "(1.3.6.1.5.5.7.3.1)"), just add:
# -and -not $_.Archived -and ( $_.EnhancedKeyUsageList -match '(1.3.6.1.5.5.7.3.1)' -or -not $_.EnhancedKeyUsageList )
Get-ChildItem -Recurse cert: `
  | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509Certificate2] -and $_.NotAfter.Date -gt (Get-Date).Date } `
  | ForEach-Object {

    # Write Cert Info (ex. for CSV holding Meta Data); Log Info having full names and additional values for reference
    Write-Output "$($_.Thumbprint);$($_.GetSerialNumberString());$($_.Archived);$($_.GetExpirationDateString());$($_.EnhancedKeyUsageList);$($_.GetName())"

    # append "Thumbprint" of Cert for unique file names
    $name = "$($_.Thumbprint)--$($_.Subject)" -replace '[\W]', '_'
    $max = $name.Length

    # reduce length to prevent filesystem errors
    if ($max -gt 150) { $max = 150 }
    $name = $name.Substring(0, $max)

    # build path
    $path = "{0}\{1}.{2}" -f $StoreToDir,$name,$CertExtension
    if (Test-Path $path) { continue } # next if cert was already written

    $oPem=new-object System.Text.StringBuilder
    [void]$oPem.AppendLine("-----BEGIN CERTIFICATE-----")
    [void]$oPem.AppendLine([System.Convert]::ToBase64String($_.RawData,$InsertLineBreaks))
    [void]$oPem.AppendLine("-----END CERTIFICATE-----")

    $oPem.toString() | add-content $path
  }

# The End