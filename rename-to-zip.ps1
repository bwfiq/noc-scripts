$files = Get-Children -Path . -File
for ($file in $files) {
  Rename-Item -Path $file.FullName -NewName $($file.FullName + ".zip") -ErrorAction Stop
}
