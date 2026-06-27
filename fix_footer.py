import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix nested footer links if it exists
    # Example:
    # <div class="footer-links">
    #     <a href="../../about.html">About Us</a>
    # <div class="footer-links">
    
    # We want to remove the second <div class="footer-links">
    # We can just look for the specific pattern that got injected
    pattern = re.compile(r'<div class="footer-links">\s*<a href="([^"]+)about\.html">About Us</a>\s*<div class="footer-links">')
    
    if pattern.search(content):
        content = pattern.sub(r'<div class="footer-links">\n                        <a href="\1about.html">About Us</a>', content)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed nested footer in {filepath}")

for root, dirs, files in os.walk(r"c:\Users\tpras\Desktop\Bitlogic Website"):
    for file in files:
        if file.endswith('.html') and 'web_screener\\build' not in root:
            process_file(os.path.join(root, file))
