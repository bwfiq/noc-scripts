# Creates folders in the working directory from the stdin list

$entries = @()
while ($line = Read-Host) {
    if ($line -match "^$") { break }
    $entries += $line
}

foreach ($entry in $entries) {
    New-Item -ItemType Directory -Path $entry -ErrorAction Stop
}
