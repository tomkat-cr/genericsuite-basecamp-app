import os
import shutil
import json
import yaml
import sys
import argparse

# Flutter does not support .svg files... yet
extra_allowed_extensions = [".png", ".jpg",
                            ".jpeg", ".gif", ".webp", ".bmp", ".wbmp"]


def clean_path(path):
    if path.startswith("./"):
        path = path[2:]
    return path


def parse_nav(nav_item, src_docs_dir, dest_docs_dir):
    """
    Parses a navigation item (list or dict) and returns a structural
    representation.
    Copies referenced files to dest_docs_dir.
    """
    if isinstance(nav_item, str):
        # Format: "Page Title" (implicitly "Page Title.md"?) - MkDocs usually
        # has "Title: path/to/file.md".
        # If just a string, it might be a file path?
        # Standard MkDocs nav: "- Page Title: path/to/page.md" or
        # "- path/to/page.md"
        return {"title": nav_item, "path": clean_path(nav_item),
                "source": "nav"}

    if isinstance(nav_item, dict):
        # Case: {"Title": "path/to/file.md"} or {"Section": [...]}
        keys = list(nav_item.keys())
        if not keys:
            return None

        title = keys[0]
        value = nav_item[title]

        if isinstance(value, str):
            # It's a page
            src_path = os.path.join(src_docs_dir, value)
            if os.path.exists(src_path):
                # Ensure destination directory exists (subdirectories)
                dest_path = os.path.join(dest_docs_dir, value)
                os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                shutil.copy2(src_path, dest_path)
                return {"title": title, "path": clean_path(value),
                        "type": "page", "source": "nav"}
            else:
                print(f"Warning: File not found: {src_path}")
                return {
                    "title": title,
                    "path": clean_path(value),
                    "type": "page",
                    "error": "not_found",
                    "source": "nav"
                }

        if isinstance(value, list):
            # It's a section
            children = []
            for child in value:
                parsed_child = parse_nav(child, src_docs_dir, dest_docs_dir)
                if parsed_child:
                    children.append(parsed_child)
            return {"title": title, "children": children, "type": "section",
                    "source": "nav"}

    return None


def main():
    parser = argparse.ArgumentParser(
        description="Convert MkDocs to Flutter Assets")
    parser.add_argument("--repo_path", required=True,
                        help="Path to the genericsuite-basecamp repository")
    parser.add_argument("--output_dir", default="assets/docs",
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
    dest_dir = args.output_dir

    # Clean output directory
    if os.path.exists(dest_dir):
        shutil.rmtree(dest_dir)
    os.makedirs(dest_dir)

    manifest = []
    files_processed = []
    nav = config.get("nav", [])

    if not nav:
        print("Warning: No 'nav' section found in mkdocs.yml. "
              "Scanning docs_dir not implemented yet (using simple walk).")
        # TODO: Implement auto-discovery if nav is missing
    else:
        for item in nav:
            parsed = parse_nav(item, docs_dir, dest_dir)
            if parsed:
                manifest.append(parsed)
                if "path" in parsed:
                    files_processed.append(parsed["path"])
                elif "children" in parsed:
                    for child in parsed["children"]:
                        if "path" in child:
                            files_processed.append(child["path"])

    print(f"Processed {len(files_processed)} files")
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

                print(
                    f"Processing file: {rel_path}"
                    # f"\n  {src_file}\n  {dest_file}"
                )

                os.makedirs(os.path.dirname(dest_file), exist_ok=True)
                shutil.copy2(src_file, dest_file)

                if file.endswith(".md"):
                    final_file = clean_path(rel_path)
                    # print(f"Processing .md file: {final_file}")
                    # Read the file and get the first line as the title
                    with open(src_file, "r") as f:
                        title = f.readline().strip()
                        if title.startswith("# "):
                            title = title[2:]
                    manifest.append(
                        {"title": title, "path": final_file, "type": "page",
                         "source": "external"})
                    files_processed.append(final_file)

    manifest_path = os.path.join(
        os.path.dirname(dest_dir), "docs_manifest.json")
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)

    print(f"Conversion complete. Manifest saved to {manifest_path}")


if __name__ == "__main__":
    main()
