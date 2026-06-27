$files = Get-ChildItem -Path . -Filter *.html -Recurse -File
foreach ($file in $files) {
    if ($file.FullName -match "web_screener\\build") { continue }
    $content = Get-Content $file.FullName -Raw
    
    if ($content -match "G-4FZCTFGJFJ") {
        $newContent = $content -replace "G-4FZCTFGJFJ", "G-YLMLJEYY7R"
        Set-Content -Path $file.FullName -Value $newContent -NoNewline
        Write-Host "Updated $($file.FullName)"
    }
}
