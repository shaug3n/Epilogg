#!/usr/bin/env python3
import argparse
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "EpiLogg/Assets.xcassets/AppIcon.appiconset"
EXPECTED_ICONS = {
    "AppIcon.png",
    "AppIcon-Dark.png",
    "AppIcon-Tinted.png",
}
PUBLIC_BASE_URL = "https://epilogg.haugentech.no"
SUPPORT_EMAIL = "epilogg@haugentech.no"
REQUIRED_SITE_TEXT = {
    "Site/index.html": [
        "EpiLogg",
        f"{PUBLIC_BASE_URL}/personvern",
        f"{PUBLIC_BASE_URL}/support",
    ],
    "Site/personvern/index.html": [
        SUPPORT_EMAIL,
        "lagres lokalt",
        "Apple-sikkerhetskopi",
        "JSON",
        "slette",
        "3. oktober 2026",
    ],
    "Site/support/index.html": [
        SUPPORT_EMAIL,
        "medisinske råd",
        "nødtjenester",
        f"{PUBLIC_BASE_URL}/personvern",
    ],
}


def png_info(path: Path) -> tuple[int, int, int]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise AssertionError(f"{path} is not a PNG")
    width, height, _, color_type = struct.unpack(">IIBB", data[16:26])
    return width, height, color_type


def validate_brand() -> None:
    catalog = json.loads((ICON_DIR / "Contents.json").read_text())
    filenames = {image.get("filename") for image in catalog["images"]}
    missing = EXPECTED_ICONS - filenames
    assert not missing, f"missing icon appearances: {missing}"
    for name in EXPECTED_ICONS:
        width, height, color_type = png_info(ICON_DIR / name)
        assert (width, height) == (1024, 1024), f"{name} is {width}x{height}"
        assert color_type == 2, f"{name} must be RGB without alpha; PNG color type={color_type}"
    marketing = ROOT / "Distribution/Marketing/EpiLogg-AppIcon-1024.png"
    assert png_info(marketing)[:2] == (1024, 1024)
    assert (ROOT / "Brand/EpiLoggLogo.svg").exists()
    icon_composer = ROOT / "Brand/AppIcon.icon/icon.json"
    icon_document = json.loads(icon_composer.read_text())
    assert icon_document["groups"], "Icon Composer source has no imported layers"


def validate_site() -> None:
    site_text = []
    for relative, phrases in REQUIRED_SITE_TEXT.items():
        text = (ROOT / relative).read_text()
        site_text.append(text)
        for phrase in phrases:
            assert phrase.casefold() in text.casefold(), f"{relative} missing {phrase!r}"

    assert (ROOT / "Site/styles.css").exists()
    vercel = json.loads((ROOT / "Site/vercel.json").read_text())
    assert vercel.get("cleanUrls") is True
    assert vercel.get("trailingSlash") is False

    combined_html = "\n".join(site_text).casefold()
    assert "<script" not in combined_html, "site must not load scripts or trackers"
    assert "support@epilogg.no" not in combined_html
    assert "https://epilogg.no" not in combined_html


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--brand", action="store_true")
    parser.add_argument("--site", action="store_true")
    args = parser.parse_args()
    if args.brand:
        validate_brand()
    elif args.site:
        validate_site()
    else:
        parser.error("select a validation group")
