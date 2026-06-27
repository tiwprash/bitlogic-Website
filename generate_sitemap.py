import os
import datetime

base_dir = r"c:\Users\tpras\Desktop\Bitlogic Website"
domain = "https://bitlogic.info"

urls = []
for root, dirs, files in os.walk(base_dir):
    for file in files:
        # Exclude web_screener entirely and verified.html
        if 'web_screener' in root:
            continue
        if file == 'verified.html':
            continue
            
        if file.endswith('.html'):
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
                "lastmod": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S+00:00"),
                "changefreq": changefreq,
                "priority": priority
            })

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

# Write sitemap.xml with utf-8 encoding (no BOM)
sitemap_path = os.path.join(base_dir, 'sitemap.xml')
with open(sitemap_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(xml_content))

print(f"Generated updated sitemap.xml at {sitemap_path}")
