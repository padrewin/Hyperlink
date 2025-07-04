import os, requests, xml.etree.ElementTree as ET
from datetime import datetime
from pathlib import Path
import markdown

REPO = os.getenv("GITHUB_REPOSITORY")
RELEASE_TAG = os.getenv("RELEASE_TAG")

# 1. Obține datele despre release
if RELEASE_TAG:
    api_url = f"https://api.github.com/repos/{REPO}/releases/tags/{RELEASE_TAG}"
else:
    api_url = f"https://api.github.com/repos/{REPO}/releases/latest"

response = requests.get(api_url)
data = response.json()

# DEBUG (doar dacă ceva e în neregulă)
if not isinstance(data, dict) or "tag_name" not in data:
    print("❌ API GitHub nu a returnat un release valid:")
    print(data)
    raise SystemExit(1)

# 2. Extrage datele
try:
    version = data["tag_name"].lstrip("v")
    pub_date = datetime.strptime(data["published_at"], "%Y-%m-%dT%H:%M:%SZ")
    pub_date_str = pub_date.strftime("%a, %d %b %Y %H:%M:%S +0000")

    asset = next((a for a in data["assets"] if a["name"].endswith(".dmg")), None)
    if not asset:
        raise Exception("❌ Nu s-a găsit niciun fișier .dmg în release-ul curent.")

    zip_url = asset["browser_download_url"]
    length = asset["size"]
    release_notes_md = data.get("body", "No release notes provided.")
except Exception as e:
    print("❌ Eroare la extragerea datelor din JSON:")
    print(data)
    raise e

# 3. Generează release notes HTML și salvează
release_notes_html = markdown.markdown(release_notes_md)
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
    "url": zip_url,
    "sparkle:version": version.replace(".", ""),
    "sparkle:shortVersionString": version,
    "length": str(length),
    "type": "application/octet-stream"
})

import xml.dom.minidom

rough_string = ET.tostring(rss, encoding="utf-8")
reparsed = xml.dom.minidom.parseString(rough_string)
pretty_xml = reparsed.toprettyxml(indent="  ")

with open("website/updates/appcast.xml", "w", encoding="utf-8") as f:
    f.write(pretty_xml)

print("✅ appcast.xml generat:")
print(pretty_xml)
