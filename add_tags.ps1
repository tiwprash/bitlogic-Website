$snippet = @"
<head>
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-4FZCTFGJFJ"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-4FZCTFGJFJ');
</script>
"@

$files = Get-ChildItem -Path . -Filter *.html -Recurse -File
foreach ($file in $files) {
    if ($file.FullName -match "web_screener\\build") { continue }
    $content = Get-Content $file.FullName -Raw
    
    # Check if already injected
    if ($content -match "G-4FZCTFGJFJ") {
        Write-Host "Skipping $($file.Name) - already has tag"
        continue
    }

    $newContent = $content -replace "(?i)<head>", $snippet
    Set-Content -Path $file.FullName -Value $newContent -NoNewline
    Write-Host "Updated $($file.FullName)"
}
