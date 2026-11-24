import os
import datetime
import subprocess

base_dir = r"c:\Users\tpras\Desktop\Bitlogic Website"
domain = "https://bitlogic.info"


def last_modified(path):
    """Date of the file's last git commit, so Google sees real change dates."""
    try:
        out = subprocess.run(['git', 'log', '-1', '--format=%cI', '--', path], cwd=base_dir,
                             capture_output=True, text=True, timeout=20).stdout.strip()
        if out:
            return out
    except Exception:
        pass
    mtime = datetime.datetime.fromtimestamp(os.path.getmtime(path), datetime.timezone.utc)
    return mtime.strftime("%Y-%m-%dT%H:%M:%S+00:00")


urls = []
for root, dirs, files in os.walk(base_dir):
    for file in files:
        # Exclude web_screener entirely and verified.html
        if 'web_screener' in root:
            continue
        if file in ('verified.html', 'app.html', 'pro-thanks.html'):
            continue

        if file.endswith('.html'):
            # Skip noindex pages and redirect pages (old URLs that point elsewhere)
            with open(os.path.join(root, file), encoding='utf-8', errors='ignore') as fh:
                head = fh.read(4000)
                if 'content="noindex' in head or 'http-equiv="refresh"' in head:
                    continue
            # Get relative path
            rel_path = os.path.relpath(os.path.join(root, file), base_dir).replace('\\', '/')
            if rel_path == "index.html":
                url = f"{domain}/"
            elif rel_path.endswith("/index.html"):
                url = f"{domain}/{rel_path[:-10]}"
            else:
                url = f"{domain}/{rel_path}"

            # Determine priority and changefreq
            priority = "0.8"
            changefreq = "weekly"

            if url == f"{domain}/":
                priority = "1.0"
                changefreq = "daily"
            elif "/crypto-screener/" in url:
                priority = "0.9"
                changefreq = "weekly"
            elif "/blog/" in url:
                priority = "0.7"
                changefreq = "monthly"
            elif "/privacy.html" in url or "/terms.html" in url or "/data-deletion.html" in url:
                priority = "0.3"
                changefreq = "yearly"

            urls.append({
                "loc": url,
                "lastmod": last_modified(os.path.join(root, file)),
                "changefreq": changefreq,
                "priority": priority
            })

urls.sort(key=lambda u: (u["loc"] != f"{domain}/", u["loc"]))

xml_content = ['<?xml version="1.0" encoding="UTF-8"?>',
               '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']

for u in urls:
    xml_content.append('  <url>')
    xml_content.append(f'    <loc>{u["loc"]}</loc>')
    xml_content.append(f'    <lastmod>{u["lastmod"]}</lastmod>')
    xml_content.append(f'    <changefreq>{u["changefreq"]}</changefreq>')
    xml_content.append(f'    <priority>{u["priority"]}</priority>')
    xml_content.append('  </url>')

xml_content.append('</urlset>')

# Write the same sitemap under two names: sitemap-pages.xml is the one submitted
# to Search Console, sitemap.xml stays for robots.txt and older references.
for name in ('sitemap.xml', 'sitemap-pages.xml'):
    sitemap_path = os.path.join(base_dir, name)
    with open(sitemap_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(xml_content) + '\n')
    print(f"Generated {name} at {sitemap_path}")
