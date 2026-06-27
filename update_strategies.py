import os
import re

strategies_dir = r"c:\Users\tpras\Desktop\Bitlogic Website\strategies"

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Determine relative path back to root
    rel_path = "../" if filepath.endswith("strategies\\index.html") else "../../"

    # New nav block
    new_nav = f"""                <div class="nav-links">
                    <a href="{rel_path}about.html">About</a>
                    <a href="{rel_path}index.html#features">Features</a>
                    <a href="{rel_path}index.html#indicators">Indicators</a>
                    <a href="{rel_path}index.html#exchanges">Exchanges</a>
                    <a href="{rel_path}strategies/index.html">Strategies</a>
                    <a href="{rel_path}crypto-screener/">Crypto Screener</a>
                
                    <div class="nav-download-dropdown">
                        <a href="#" class="nav-cta-btn" onclick="event.preventDefault()">Download Free ▾</a>
                        <div class="dropdown-content">
                            <a href="https://play.google.com/store/apps/details?id=com.bitlogic.screener.pro" target="_blank">Android App</a>
                            <a href="https://apps.microsoft.com/detail/9PGBXSLTP4DS?hl=en-us&gl=IN&ocid=pdpshare" target="_blank">Windows App</a>
                        </div>
                    </div>
                </div>"""

    # Replace the nav block
    # Find <div class="nav-links"> and everything inside it up to its closing </div>
    # A bit tricky since there is a nested div.nav-download-dropdown. We will use a regex that looks for </nav>
    
    # Let's replace the whole nav block by searching between <div class="nav-links"> and </nav>
    pattern_nav = re.compile(r'<div class="nav-links">.*?</nav>', re.DOTALL)
    replacement_nav = new_nav + "\n            </div>\n        </nav>"
    
    content = pattern_nav.sub(replacement_nav, content)

    # Replace footer year
    content = content.replace("2024 BitLogic", "2026 BitLogic")
    # Just in case it has span id=year
    content = content.replace('id="year">2024</span>', 'id="year">2026</span>')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, dirs, files in os.walk(strategies_dir):
    for file in files:
        if file.endswith('.html'):
            process_file(os.path.join(root, file))

print("Done updating strategy pages.")
