import os, requests, xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path
import markdown
import xml.dom.minidom

# Variabile de mediu setate de GitHub Actions
REPO = os.getenv("GITHUB_REPOSITORY")
RELEASE_TAG = os.getenv("RELEASE_TAG")

# 1. Obține datele despre release
if RELEASE_TAG:
    api_url = f"https://api.github.com/repos/{REPO}/releases/tags/{RELEASE_TAG}"
else:
    api_url = f"https://api.github.com/repos/{REPO}/releases/latest"

response = requests.get(api_url)
data = response.json()

# DEBUG
if not isinstance(data, dict) or "tag_name" not in data:
    print("❌ API GitHub nu a returnat un release valid:")
    print(data)
    raise SystemExit(1)

# 2. Extrage datele
try:
    version = data["tag_name"].lstrip("v")
    pub_date = datetime.strptime(data["published_at"], "%Y-%m-%dT%H:%M:%SZ")
    pub_date_str = pub_date.strftime("%a, %d %b %Y %H:%M:%S +0000")

    # Caută .zip (nu .dmg)
    asset = next((a for a in data["assets"] if a["name"].endswith(".zip")), None)
    if not asset:
        raise Exception("❌ Nu s-a găsit niciun fișier .zip în release-ul curent.")

    download_url = asset["browser_download_url"]
    length = asset["size"]
    release_notes_md = data.get("body", "No release notes provided.")
except Exception as e:
    print("❌ Eroare la extragerea datelor din JSON:")
    print(data)
    raise e

# 3. Generează release notes HTML complet stilizat
body_html = markdown.markdown(release_notes_md)

release_notes_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Release Notes {version}</title>
  <style>
    body {{ font-family: -apple-system, sans-serif; margin: 2em; line-height: 1.6; }}
    h1, h2, h3 {{ color: #333; }}
    code {{ background: #f4f4f4; padding: 2px 4px; border-radius: 4px; font-family: monospace; }}
    pre {{ background: #f4f4f4; padding: 10px; border-radius: 4px; overflow-x: auto; }}
    a {{ color: #0366d6; text-decoration: none; }}
    a:hover {{ text-decoration: underline; }}
  </style>
</head>
<body>
  <h1>What’s new in version {version}</h1>
  {body_html}
</body>
</html>"""

# Salvează fișierul HTML
notes_path = Path("website/updates/releasenotes")
notes_path.mkdir(parents=True, exist_ok=True)
notes_file = notes_path / f"{version}.html"
notes_file.write_text(release_notes_html, encoding="utf-8")

# 4. Generează appcast.xml
rss = ET.Element("rss", version="2.0", attrib={
    "xmlns:sparkle": "http://www.andymatuschak.org/xml-namespaces/sparkle",
    "xmlns:dc": "http://purl.org/dc/elements/1.1/"
})
channel = ET.SubElement(rss, "channel")
ET.SubElement(channel, "title").text = "Hyperlink Updates"
ET.SubElement(channel, "link").text = "https://hyperlink.colddev.dev"
ET.SubElement(channel, "description").text = "Update feed for Hyperlink"
ET.SubElement(channel, "language").text = "en"

item = ET.SubElement(channel, "item")
ET.SubElement(item, "title").text = f"Version {version}"
ET.SubElement(item, "sparkle:releaseNotesLink").text = f"https://hyperlink.colddev.dev/updates/releasenotes/{version}.html"
ET.SubElement(item, "pubDate").text = pub_date_str
ET.SubElement(item, "enclosure", {
    "url": download_url,
    "sparkle:version": version.replace(".", ""),
    "sparkle:shortVersionString": version,
    "length": str(length),
    "type": "application/octet-stream"
})

# 5. Scrie XML-ul într-un fișier frumos formatat
rough_string = ET.tostring(rss, encoding="utf-8")
reparsed = xml.dom.minidom.parseString(rough_string)
pretty_xml = reparsed.toprettyxml(indent="  ")

appcast_path = Path("website/updates/appcast.xml")
appcast_path.write_text(pretty_xml, encoding="utf-8")

print("✅ appcast.xml și releasenotes generate cu succes:")
print(f"- {appcast_path}")
print(f"- {notes_file}")
