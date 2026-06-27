$files = Get-ChildItem -Path . -Filter *.html -Recurse -File
foreach ($file in $files) {
    if ($file.FullName -match "web_screener\\build") { continue }
    if ($file.FullName -match "about\.html") { continue }
    if ($file.FullName -match "index\.html$" -and $file.FullName -notmatch "strategies|crypto-screener") { continue } # Already updated index.html
    if ($file.FullName -match "privacy\.html") { continue } # Already updated privacy.html

    $content = Get-Content $file.FullName -Raw

    if ($content -match ">About<") { continue }

    $depth = ($file.FullName.Substring($PWD.Path.Length + 1) -split '\\').Count - 1
    
    $prefix = ""
    for ($i = 0; $i -lt $depth; $i++) {
        $prefix += "../"
    }

    $aboutLink = "<a href=`"${prefix}about.html`">About</a>"

    $newContent = $content -replace '(<div class="nav-links">\s*)', "`$1$aboutLink`n                    "
    
    # Also update the footer if it has Legal Policies
    $newContent = $newContent -replace '<h4>Legal Policies</h4>', "<h4>Company & Legal</h4>`n                    <div class=`"footer-links`">`n                        <a href=`"${prefix}about.html`">About Us</a>"

    Set-Content -Path $file.FullName -Value $newContent -NoNewline
    Write-Host "Updated $($file.FullName)"
}
