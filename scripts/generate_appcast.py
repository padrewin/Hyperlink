# scripts/generate_appcast.py

import os, requests, xml.etree.ElementTree as ET
from datetime import datetime

REPO = os.getenv("GITHUB_REPOSITORY")
RELEASE_TAG = os.getenv("RELEASE_TAG")

api_url = f"https://api.github.com/repos/{REPO}/releases/tags/{RELEASE_TAG}"
response = requests.get(api_url)
data = response.json()

version = data["tag_name"].lstrip("v")  # e.g. "1.0.5"
pub_date = datetime.strptime(data["published_at"], "%Y-%m-%dT%H:%M:%SZ")
pub_date_str = pub_date.strftime("%a, %d %b %Y %H:%M:%S +0000")

asset = next(a for a in data["assets"] if a["name"].endswith(".zip"))
zip_url = asset["browser_download_url"]
length = asset["size"]

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

ET.ElementTree(rss).write("appcast.xml", encoding="utf-8", xml_declaration=True)
with open("appcast.xml", "r") as f:
    print(f.read())
