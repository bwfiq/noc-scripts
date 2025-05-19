$files = Get-ChildItem -Path . -File
foreach ($file in $files) {
  Rename-Item -Path $file.FullName -NewName $($file.FullName + ".zip") -ErrorAction Stop
}
