#
# split Lotus Notes VCF for import to Outlook
#

$infile = "NotesContacts"

Write-Host "Processing Lotus Notes vCard File: $infile.vcf"

$i = 0
$outfile = "$infile.{0:0000}.vcf" -f $i

Get-Content "$infile.vcf" | ForEach-Object {
  if ( $_ -match "^BEGIN:VCARD" ) {
    $i++
    $outfile = "$infile.{0:0000}.vcf" -f $i
  }
  $_ | out-file -append -encoding "ASCII" "$outfile"
}

Write-Host vCard processing completed, processed $i vCard entries
