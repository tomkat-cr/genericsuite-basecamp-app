import os
import shutil
import json
import yaml
import sys
import argparse

from translate_module import translate
from translate_ai_module import translate as translate_ai

# Flutter does not support .svg files... yet
extra_allowed_extensions = [".png", ".jpg",
                            ".jpeg", ".gif", ".webp", ".bmp", ".wbmp"]


errors_happened = False


def clean_path(path):
    if path.startswith("./"):
        path = path[2:]
    return path


def get_title(content: str, default_title: str = "") -> str:
    content_lines = content.splitlines()
    title = content_lines[0].strip() if content_lines else default_title
    if title.startswith("# "):
        title = title[2:]
    return title


def translate_content(content, filename, dest_lang, force=''):
    global errors_happened

    if content == "":
        return {"text": "", "error_message": "Empty content"}

    if not os.environ.get("OPENAI_API_KEY"):
        force = "google"
    elif force != "google":
        force = "openai"

    if force == "openai":
        print(f"Translating {filename} using OpenAI...")
        translate_resp = translate_ai(content, dest_lang)
    else:
        print(f"Translating {filename} using Google...")
        translate_resp = translate(content, dest_lang)

    if translate_resp["text"] == "":
        translate_resp["error_message"] = "Empty response"

    if translate_resp["error_message"] != "":
        errors_happened = True
        print("")
        print(f"ERROR translating {filename}: "
              f"{translate_resp['error_message']}")
        print("")

    return translate_resp


def parse_nav(nav_item, src_docs_dir, dest_docs_dir, dest_lang) -> dict:
    """
    Parses a navigation item (list or dict) and returns a structural
    representation.
    Copies referenced files to dest_docs_dir.
    """
    global errors_happened
    if isinstance(nav_item, str):
        # Format: "Page Title" (implicitly "Page Title.md"?) - MkDocs usually
        # has "Title: path/to/file.md".
        # If just a string, it might be a file path?
        # Standard MkDocs nav: "- Page Title: path/to/page.md" or
        # "- path/to/page.md"
        return {"title": nav_item, "path": clean_path(nav_item),
                "source": "nav", "lang": dest_lang}

    if isinstance(nav_item, dict):
        # Case: {"Title": "path/to/file.md"} or {"Section": [...]}
        keys = list(nav_item.keys())
        if not keys:
            return None

        title = keys[0]
        dest_file = nav_item[title]

        print(f"Processing NAV item: {dest_file}...")

        if isinstance(dest_file, str):
            # It's a page
            src_path = os.path.join(src_docs_dir, dest_file)
            if os.path.exists(src_path):
                # Ensure destination directory exists (subdirectories)
                dest_path = os.path.join(dest_docs_dir, dest_file)
                os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                shutil.copy2(src_path, dest_path)

                # Translate the file to Spanish (or any other language)
                if dest_lang != "en":
                    with open(dest_path, "r") as f:
                        content = f.read()
                    translate_resp = translate_content(
                        content, dest_file, dest_lang)
                    if translate_resp["error_message"] == "":
                        with open(dest_path, "w") as f:
                            f.write(translate_resp["text"])
                        title = get_title(
                            translate_resp["text"], f'[ENG] {title}')

                return {"title": title, "path": clean_path(dest_file),
                        "type": "page", "source": "nav", "lang": dest_lang}
            else:
                print(f"Warning: File not found: {src_path}")
                return {
                    "title": title,
                    "path": clean_path(dest_file),
                    "type": "page",
                    "error": "not_found",
                    "source": "nav",
                    "lang": dest_lang
                }

        if isinstance(dest_file, list):
            # It's a section
            children = []
            for child in dest_file:
                parsed_child = parse_nav(child, src_docs_dir, dest_docs_dir,
                                         dest_lang)
                if parsed_child:
                    children.append(parsed_child)

            if dest_lang != "en":
                translate_resp = translate_content(
                    title, dest_file, dest_lang, "google")
                if translate_resp["error_message"] == "":
                    title = get_title(
                        translate_resp["text"], f'[ENG] {title}')

            return {"title": title, "children": children, "type": "section",
                    "source": "nav", "lang": dest_lang}

    return None


def main():
    parser = argparse.ArgumentParser(
        description="Convert MkDocs to Flutter Assets")
    parser.add_argument("--repo_path", required=True,
                        help="Path to the genericsuite-basecamp repository")
    parser.add_argument("--output_dir", default="assets/docs_en",
                        help="Path to output assets")
    parser.add_argument("--output_dir_esp", default="assets/docs_es",
                        help="Path to output assets")
    args = parser.parse_args()

    repo_path = args.repo_path
    mkdocs_path = os.path.join(repo_path, "mkdocs.yml")

    if not os.path.exists(mkdocs_path):
        print(f"Error: mkdocs.yml not found at {mkdocs_path}")
        sys.exit(1)

    with open(mkdocs_path, "r") as f:
        content = f.read()

    # Pre-process content to remove unsupported tags
    lines = content.splitlines()
    cleaned_lines = [line for line in lines if "!!python/name:" not in line]
    cleaned_content = "\n".join(cleaned_lines)

    try:
        config = yaml.safe_load(cleaned_content)
    except Exception as e:
        print(f"YAML loading failed even after cleanup: {e}")
        sys.exit(1)

    docs_dir = os.path.join(repo_path, config.get("docs_dir", "docs"))
    if "docs_for_ftp" in docs_dir:
        docs_dir = os.path.join(repo_path, "docs")

    dest_dir = args.output_dir
    dest_dir_esp = args.output_dir_esp

    # Clean output directory
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir)
    os.makedirs(dest_dir)

    if os.path.exists(dest_dir_esp):
        shutil.rmtree(dest_dir_esp)
    os.makedirs(dest_dir_esp)

    manifest = []
    manifest_esp = []
    files_processed = []
    nav = config.get("nav", [])

    if not nav:
        print("Warning: No 'nav' section found in mkdocs.yml. "
              "Scanning docs_dir not implemented yet (using simple walk).")
        # TODO: Implement auto-discovery if nav is missing
    else:
        # English
        for item in nav:
            parsed = parse_nav(item, docs_dir, dest_dir, "en")
            if parsed:
                manifest.append(parsed)
                if "path" in parsed:
                    files_processed.append(parsed["path"])
                elif "children" in parsed:
                    for child in parsed["children"]:
                        if "path" in child:
                            files_processed.append(child["path"])
        # Spanish
        for item in nav:
            parsed = parse_nav(item, docs_dir, dest_dir_esp, "es")
            if parsed:
                manifest_esp.append(parsed)
                if "path" in parsed:
                    files_processed.append(parsed["path"])
                elif "children" in parsed:
                    for child in parsed["children"]:
                        if "path" in child:
                            files_processed.append(child["path"])
        manifest.extend(manifest_esp)

    print(f"Processed {len(files_processed)} NAV files")
    print(f"files_processed: {files_processed}")

    # Copy images?
    # Simple strategy: Copy everything from docs_dir to dest_dir that hasn't
    # been copied?
    # Or just copy the whole docs_dir structure first, then build manifest?
    # Better strategy: Copy all non-md files (images) to preserve structure.
    for root, dirs, files in os.walk(docs_dir):
        for file in files:
            if (file.endswith(".md") and file not in files_processed) or \
                (not file.endswith(".md") and
               file.endswith(tuple(extra_allowed_extensions)) and
               file not in files_processed):

                rel_path = os.path.relpath(os.path.join(root, file), docs_dir)
                src_file = os.path.join(root, file)
                dest_file = os.path.join(dest_dir, rel_path)
                dest_file_esp = os.path.join(dest_dir_esp, rel_path)

                print(f"Processing file: {rel_path}")

                os.makedirs(os.path.dirname(dest_file), exist_ok=True)
                os.makedirs(os.path.dirname(dest_file_esp), exist_ok=True)
                shutil.copy2(src_file, dest_file)
                shutil.copy2(src_file, dest_file_esp)

                if file.endswith(".md"):
                    final_file = clean_path(rel_path)

                    # Read the file and get the first line as the title
                    with open(src_file, "r") as f:
                        content = f.read()
                        title = get_title(content, "--No title--")
                    manifest.append(
                        {
                            "title": title,
                            "path": final_file,
                            "type": "page",
                            "source": "external",
                            "lang": "en"
                        })
                    files_processed.append(final_file)

                    translate_resp = translate_content(
                        content, final_file, "es")
                    if translate_resp["error_message"] == "":
                        os.makedirs(os.path.dirname(
                            dest_file_esp), exist_ok=True)
                        with open(dest_file_esp, "w") as f:
                            f.write(translate_resp["text"])
                        title_esp = get_title(
                            translate_resp["text"], f'[ENG] {title}')
                        manifest.append(
                            {
                                "title": title_esp,
                                "path": final_file,
                                "type": "page",
                                "source": "external",
                                "lang": "es"
                            })

                else:
                    files_processed.append(rel_path)

    manifest_path = os.path.join(
        os.path.dirname(dest_dir), "docs_manifest.json")
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)

    print(f"Conversion complete. Manifest saved to {manifest_path}")
    if errors_happened:
        print("\n")
        print("ERROR: Errors happened during the conversion. Not all files")
        print("were translated. Please check the errors above.")
        print("\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
