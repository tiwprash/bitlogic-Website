import os
import re
import json

base_dir = r"c:\Users\tpras\Desktop\Bitlogic Website"

faq_html = """
        <section class="faq-section" style="background: var(--bg-card); padding: 4rem 2rem; border-top: 1px solid var(--border-color);">
            <div class="container" style="max-width: 800px; margin: 0 auto;">
                <h2 style="text-align: center; margin-bottom: 2rem; font-size: 2.5rem;">Frequently Asked Questions</h2>
                <div class="faq-item" style="margin-bottom: 1.5rem;">
                    <h3 style="font-size: 1.25rem; margin-bottom: 0.5rem; color: var(--text-primary);">Is BitLogic free to use?</h3>
                    <p style="color: var(--text-secondary);">Yes, you can download and use the basic features of the BitLogic crypto screener for free on Android and Windows.</p>
                </div>
                <div class="faq-item" style="margin-bottom: 1.5rem;">
                    <h3 style="font-size: 1.25rem; margin-bottom: 0.5rem; color: var(--text-primary);">Do I need to know how to code to use BitLogic?</h3>
                    <p style="color: var(--text-secondary);">No coding experience is required. BitLogic is a 100% no-code crypto strategy builder with a visual drag-and-drop interface.</p>
                </div>
                <div class="faq-item" style="margin-bottom: 1.5rem;">
                    <h3 style="font-size: 1.25rem; margin-bottom: 0.5rem; color: var(--text-primary);">Which exchanges are supported?</h3>
                    <p style="color: var(--text-secondary);">BitLogic currently supports real-time market scanning for Binance, Bybit, CoinDCX, Kraken, and OKX.</p>
                </div>
            </div>
        </section>
"""

# JSON-LD Schemas
software_schema = {
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "BitLogic",
  "operatingSystem": "Android, Windows",
  "applicationCategory": "FinanceApplication",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  },
  "description": "No-code crypto strategy builder and live market screener."
}

faq_schema = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "Is BitLogic free to use?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes, you can download and use the basic features of the BitLogic crypto screener for free on Android and Windows."
      }
    },
    {
      "@type": "Question",
      "name": "Do I need to know how to code to use BitLogic?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "No coding experience is required. BitLogic is a 100% no-code crypto strategy builder with a visual drag-and-drop interface."
      }
    },
    {
      "@type": "Question",
      "name": "Which exchanges are supported?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "BitLogic currently supports real-time market scanning for Binance, Bybit, CoinDCX, Kraken, and OKX."
      }
    }
  ]
}

def get_breadcrumb(path, is_home, is_blog_index, blog_name=""):
    schema = {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "itemListElement": [
        {
          "@type": "ListItem",
          "position": 1,
          "name": "Home",
          "item": "https://bitlogic.info/"
        }
      ]
    }
    
    if is_blog_index:
        schema["itemListElement"].append({
            "@type": "ListItem",
            "position": 2,
            "name": "Blog",
            "item": "https://bitlogic.info/blog/"
        })
    elif not is_home and blog_name:
        schema["itemListElement"].append({
            "@type": "ListItem",
            "position": 2,
            "name": "Blog",
            "item": "https://bitlogic.info/blog/"
        })
        schema["itemListElement"].append({
            "@type": "ListItem",
            "position": 3,
            "name": blog_name,
            "item": f"https://bitlogic.info/blog/{os.path.basename(os.path.dirname(path))}/"
        })
    
    return schema

def get_article(title, desc):
    return {
      "@context": "https://schema.org",
      "@type": "Article",
      "headline": title,
      "description": desc,
      "author": {
        "@type": "Organization",
        "name": "BitLogic"
      }
    }

for root, dirs, files in os.walk(base_dir):
    for file in files:
        if file.endswith(".html") and "web_screener\\build" not in root:
            filepath = os.path.join(root, file)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()

            # Remove all existing ld+json scripts
            content = re.sub(r'<script type="application/ld\+json">.*?</script>', '', content, flags=re.DOTALL)

            schemas = []
            
            is_home = (filepath == os.path.join(base_dir, "index.html"))
            is_blog_index = (filepath == os.path.join(base_dir, "blog", "index.html"))
            is_blog_post = ("blog\\prebuilt-" in filepath)

            # Insert FAQ section into index.html
            if is_home and "faq-section" not in content:
                content = content.replace("</main>", faq_html + "\n    </main>")
                schemas.append(software_schema)
                schemas.append(faq_schema)
                schemas.append(get_breadcrumb(filepath, True, False))

            if is_blog_index:
                schemas.append(get_breadcrumb(filepath, False, True))
                
            if is_blog_post:
                # Extract title and description
                title_match = re.search(r'<title>(.*?)</title>', content)
                desc_match = re.search(r'<meta name="description" content="(.*?)">', content)
                title = title_match.group(1) if title_match else "Crypto Trading Strategy"
                desc = desc_match.group(1) if desc_match else "Learn this crypto trading strategy."
                
                schemas.append(get_article(title, desc))
                # Generate breadcrumb name from title
                short_title = title.split(" (")[0]
                schemas.append(get_breadcrumb(filepath, False, False, short_title))

            if schemas:
                # Append schemas to head
                script_tags = []
                for s in schemas:
                    script_tags.append('<script type="application/ld+json">\n' + json.dumps(s, indent=2) + '\n    </script>')
                
                all_scripts = "\n    ".join(script_tags) + "\n</head>"
                content = content.replace("</head>", all_scripts)

            with open(filepath, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"Processed JSON-LD for {filepath}")

print("JSON-LD update complete.")
