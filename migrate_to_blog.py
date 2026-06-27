import os

base_dir = r"c:\Users\tpras\Desktop\Bitlogic Website"

# Update all references in all HTML files
for root, dirs, files in os.walk(base_dir):
    for file in files:
        if file.endswith(".html") and "web_screener\\build" not in root:
            filepath = os.path.join(root, file)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()

            new_content = content
            
            # Replace hrefs
            new_content = new_content.replace('href="strategies/', 'href="blog/')
            new_content = new_content.replace('href="../strategies/', 'href="../blog/')
            new_content = new_content.replace('href="../../strategies/', 'href="../../blog/')
            
            # Replace navigation text
            new_content = new_content.replace('>Strategies</a>', '>Blog</a>')
            
            # Update specific text in the blog index
            if "blog\\index.html" in filepath:
                new_content = new_content.replace('Trading Strategies Hub', 'BitLogic Crypto Trading Blog')
                new_content = new_content.replace('Explore high-win-rate algorithmic setups', 'Read our latest posts on crypto trading, strategy tutorials, and algorithmic setups')
                new_content = new_content.replace('<title>Crypto Trading Strategies', '<title>Crypto Trading Blog')

            if new_content != content:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"Updated references in {filepath}")

print("Migration to blog section complete.")
