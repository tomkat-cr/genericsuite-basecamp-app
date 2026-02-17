import os
import time
import shutil
import json
import yaml
import sys
import argparse

from translate_module import translate
from translate_ai_module import translate as translate_ai


# TODO: add language to the "docs_manifest.json" entries to make easier and
# more natural the Scaffold > body > ListView > MarkdownBody >
#    // Resolve relative path to assets

class DocsConverter:
    def __init__(self):
        self.allowed_extensions = [
            ".md",
            # ".pdf",
            ".json",
            ".yml",
            ".yaml",
            ".toml",
            ".sh",
            # ".ico",
            ".png",
            ".jpg",
            ".jpeg",
            ".gif",
            ".webp",
            ".bmp",
            ".wbmp",
            # ".svg",
        ]
        self.ignore_files = [
            "package.json",
            "package-lock.json",
            "pyproject.toml",
            "CHANGELOG.md",
            "manifest.json",
            "config-example.json",
            "dynamodb_cf_template.yaml",
            "run_mcp_server.sh",
            "claude_desktop_config.json",
            "vscode_mcp_config.json",
            "deployment.yml",
            "docker-compose.yml",
            "tsconfig.json",
            "base.json",
            "nextjs.json",
            "react-library.json",
            "pnpm-lock.yaml",
            "pnpm-workspace.yaml",
            "turbo.json",
            "build_if_required.sh",
            "clean_directory.sh",
            "init_env_files.sh",
            "link_common_assets.sh",
            "run-deploy.sh",
            "build_docker_images.sh",
            "server-entrypoint.sh",
            "claude_desktop_http_config.json",
            "claude_desktop_stdio_config.json",
            "vscode_mcp_http_config.json",
            "vscode_mcp_stdio_config.json",
            "copy_env_files.sh",
            "init_app_environment.sh",
            "docs_manifest.json",
        ]
        self.languages = ["en", "es"]
        self.errors_happened = False
        self.translation = False
        self.config = None
        self.nav = None

    def clean_path(self, path: str) -> str:
        if path.startswith("./"):
            path = path[2:]
        return path

    def get_title(self, content: str, default_title: str = "") -> str:
        content_lines = content.splitlines()
        title = content_lines[0].strip() if content_lines else default_title
        if title.startswith("# "):
            title = title[2:]
        return title

    def translate_content(self, content: str, filename: str, dest_lang: str,
                          force: str = '') -> dict:
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
            self.errors_happened = True
            print("")
            print(f"ERROR translating {filename}: "
                  f"{translate_resp['error_message']}")
            print("")

        return translate_resp

    def get_title_path_from_nav_item(
            self, nav_item: str | dict,
            dest_lang: str) -> dict | None:

        if isinstance(nav_item, str):
            # Format: "Page Title" (implicitly "Page Title.md"?)
            # MkDocs usually has "Title: path/to/file.md".
            # If just a string, it might be a file path?
            # Standard MkDocs nav: "- Page Title: path/to/page.md" or
            # "- path/to/page.md"
            title = nav_item
            dest_file = self.clean_path(nav_item)
            if ":" in nav_item:
                title, dest_file = nav_item.split(":")
                dest_file = self.clean_path(dest_file)
            return {"title": title, "path": dest_file, "source": "nav",
                    "lang": dest_lang}

        if isinstance(nav_item, dict):
            # Case: {"Title": "path/to/file.md"} or {"Section": [...]}
            keys = list(nav_item.keys())
            if not keys:
                print(f"ERROR: Empty nav item: {nav_item}")
                return None

            title = keys[0]
            dest_file_or_list = nav_item[title]
            return {"title": title, "path": dest_file_or_list, "source": "nav",
                    "lang": dest_lang}

        return None

    def copy_file_and_translate(
            self,
            src_docs_dir: str,
            dest_docs_dir: str,
            dest_file: str,
            title: str,
            dest_lang: str) -> dict:
        """
        Copies a file from src_path to dest_path.
        Ensures the destination directory exists (subdirectories).
        """
        dest_file = self.clean_path(dest_file)
        src_path = os.path.join(src_docs_dir, dest_file)
        if os.path.exists(src_path):
            # Ensure destination directory exists (subdirectories)
            dest_full_path = os.path.join(
                dest_docs_dir, dest_file)

            # Copy the file to the destination directory
            os.makedirs(os.path.dirname(dest_full_path), exist_ok=True)
            shutil.copy2(src_path, dest_full_path)

            # Translate the file to Spanish (or any other language)
            if self.translation and dest_lang != "en":
                with open(dest_full_path, "r") as f:
                    content = f.read()
                translate_resp = self.translate_content(
                    content, dest_file, dest_lang)
                if translate_resp["error_message"] == "":
                    with open(dest_full_path, "w") as f:
                        f.write(translate_resp["text"])
                    title = self.get_title(
                        translate_resp["text"], f'[ENG] {title}')

            return {
                "title": title,
                "path": dest_file,
                "type": "page",
                "source": "nav",
                "lang": dest_lang}
        else:
            print(f"Warning: File not found: {src_path}")
            return {
                "title": title,
                "path": dest_file,
                "type": "page",
                "error": "not_found",
                "source": "nav",
                "lang": dest_lang
            }

    def parse_nav(
        self,
        nav_item: str | dict,
        src_docs_dir: str,
        dest_docs_dir: str,
        dest_lang: str
    ) -> dict:
        """
        Parses a navigation item (list or dict) and returns a structural
        representation.
        Copies referenced files to dest_docs_dir.
        """
        nav_components = self.get_title_path_from_nav_item(nav_item, dest_lang)
        if nav_components is None:
            return None

        title = nav_components["title"]
        dest_file = nav_components["path"]

        if isinstance(nav_item, str):
            return self.copy_file_and_translate(
                src_docs_dir,
                dest_docs_dir,
                dest_file,
                title,
                dest_lang)

        if isinstance(nav_item, dict):
            # Case: {"Title": "path/to/file.md"} or {"Section": [...]}
            print(f"Processing NAV item: {dest_file}...")

            if isinstance(dest_file, str):
                # It's a page
                return self.copy_file_and_translate(
                    src_docs_dir,
                    dest_docs_dir,
                    dest_file,
                    title,
                    dest_lang)

            if isinstance(dest_file, list):
                # It's a section
                children = []
                for child in dest_file:
                    parsed_child = self.parse_nav(
                        child,
                        src_docs_dir,
                        dest_docs_dir,
                        dest_lang)
                    if parsed_child:
                        children.append(parsed_child)

                item_to_add = {
                    "title": title,
                    "children": children,
                    "type": "section",
                    "source": "nav",
                    "lang": dest_lang}

                if self.translation and dest_lang != "en":
                    translate_resp = self.translate_content(
                        title, dest_file, dest_lang, "google")
                    if translate_resp["error_message"] == "":
                        title = self.get_title(
                            translate_resp["text"], f'[ENG] {title}')
                        item_to_add["title"] = title
                    else:
                        item_to_add["error"] = translate_resp["error_message"]

                return item_to_add

        return None

    def run(self):
        parser = argparse.ArgumentParser(
            description="Convert MkDocs to Flutter Assets")
        parser.add_argument(
            "--repo_path", required=True,
            help="Path to the genericsuite-basecamp repository")
        parser.add_argument(
            "--output_dir", default="assets/docs",
            help="Path to output assets")
        parser.add_argument(
            "--translation", default="false",
            help="Translation language")
        args = parser.parse_args()

        repo_path = args.repo_path
        mkdocs_path = os.path.join(repo_path, "mkdocs.yml")
        self.translation = args.translation.lower() == "true"

        if not os.path.exists(mkdocs_path):
            print(f"Error: mkdocs.yml not found at {mkdocs_path}")
            sys.exit(1)

        with open(mkdocs_path, "r") as f:
            content = f.read()

        # Pre-process content to remove unsupported tags
        lines = content.splitlines()
        cleaned_lines = [
            line for line in lines if "!!python/name:" not in line]
        cleaned_content = "\n".join(cleaned_lines)

        try:
            self.config = yaml.safe_load(cleaned_content)
        except Exception as e:
            print(f"YAML loading failed even after cleanup: {e}")
            sys.exit(1)

        docs_dir = os.path.join(repo_path, self.config.get("docs_dir", "docs"))
        if "docs_for_ftp" in docs_dir:
            docs_dir = os.path.join(repo_path, "docs")

        dest_dir = args.output_dir

        # Clean output directory
        if os.path.exists(dest_dir):
            shutil.rmtree(dest_dir)
        os.makedirs(dest_dir)

        for lang in self.languages:
            dest_dir_lang = os.path.join(dest_dir, lang)
            if os.path.exists(dest_dir_lang):
                shutil.rmtree(dest_dir_lang)
            os.makedirs(dest_dir_lang)

        manifest = []
        manifest_by_lang = {lang: [] for lang in self.languages}
        files_processed = []
        self.nav = self.config.get("nav", [])

        print("")
        if not self.nav:
            print("Warning: No 'nav' section found in mkdocs.yml. "
                  "Scanning docs_dir using simple walk.")
            # TODO: Implement auto-discovery of main index.md if nav is missing
        else:
            for lang in self.languages:
                for item in self.nav:
                    parsed = self.parse_nav(
                        item, f"{docs_dir}/{lang}", f"{dest_dir}/{lang}", lang)
                    if parsed:
                        manifest_by_lang[lang].append(parsed)
                        if "path" in parsed:
                            files_processed.append(parsed["path"])
                        elif "children" in parsed:
                            for child in parsed["children"]:
                                if "path" in child:
                                    files_processed.append(child["path"])
                manifest.extend(manifest_by_lang[lang])

        print("")
        print(f"Processed {len(files_processed)} NAV files")
        print(f"files_processed: {files_processed}")

        # Get titles from the mkdocs.yml file,
        # "plugins > i18n > languages > - locale: [lang]
        #   > nav_translations > [nav english title]" section

        translated_titles = {}
        for lang in self.languages:
            translated_titles[lang] = {}
            if "plugins" not in self.config:
                continue

            i18n_config = None
            for plugin in self.config["plugins"]:
                if "i18n" in plugin:
                    i18n_config = plugin["i18n"]
                    break
            if not i18n_config or "languages" not in i18n_config:
                continue

            i18n_languages = i18n_config["languages"]
            for lng in i18n_languages:
                if lng["locale"] == lang:
                    translated_titles[lang] = lng.get("nav_translations", {})
                    break

        print("")
        print(f"Translated titles: {translated_titles}")
        print("")

        # Copy images and other .md not in mkdocs
        # Simple strategy: Copy everything from docs_dir to dest_dir that
        # hasn't been copied?
        # Or just copy the whole docs_dir structure first, then build manifest?
        # Better strategy: Copy all non-md files (images) to preserve
        # structure.
        for root, dirs, files in os.walk(docs_dir):
            for file in files:
                rel_path = os.path.relpath(
                    os.path.join(root, file), docs_dir)
                src_file = os.path.join(root, file)
                dest_file = os.path.join(dest_dir, rel_path)
                base_file_dir = os.path.dirname(src_file)

                file_lang = None
                final_file = dest_file
                if base_file_dir[:-3] in ["/{lng}" for lng in self.languages]:
                    # If the file is in a language directory, get the language
                    # and update the final file path
                    file_lang = base_file_dir[:-2]
                    final_file = os.path.relpath(
                        dest_file, f'{dest_dir}/{file_lang}')

                if (not file.endswith(tuple(self.allowed_extensions)) or
                        os.path.basename(file) in self.ignore_files or
                        final_file in files_processed):
                    continue

                print(f"Processing file: {rel_path}")

                os.makedirs(os.path.dirname(dest_file), exist_ok=True)
                shutil.copy2(src_file, dest_file)

                # Check if the file is translatable, if translation is
                # activated and is not in english
                if not file.endswith(".md") or \
                        file_lang is None or \
                        file_lang == "en":
                    continue

                # Report if the file is outdated respect of the
                # english counterpart
                english_file_path = os.path.join(
                    base_file_dir[0:-2] + "en", file)
                if not os.path.exists(english_file_path):
                    print(
                        f"File '{rel_path}' is missing the english"
                        " counterpart")
                    print(f"English file: {english_file_path}")
                    continue

                english_file_date = os.path.getmtime(english_file_path)
                src_file_date = os.path.getmtime(src_file)
                if not translate:
                    if english_file_date > src_file_date:
                        print("")
                        print(
                            f"English file: {english_file_path} | "
                            "date/time: "
                            f"{time.ctime(english_file_date)}")
                        print(
                            f"Current file: {src_file} | "
                            "date/time: "
                            f"{time.ctime(src_file_date)}")
                        print(
                            f"File {rel_path} is outdated respect"
                            " of the english counterpart and"
                            " translation is disabled.\nSkipping")
                    continue

                if src_file_date > english_file_date:
                    print("")
                    print(
                        f"English file: {english_file_path} | "
                        "date/time: "
                        f"{time.ctime(english_file_date)}")
                    print(
                        f"Current file: {src_file} | "
                        "date/time: "
                        f"{time.ctime(src_file_date)}")
                    print(
                        f"File {rel_path} is more recent than"
                        " the english counterpart and"
                        " translation is enabled.\n"
                        "Do you want to translate it anyway?")

                    user_input = input(" (y/n): ")
                    if user_input.lower() != "y":
                        continue

                # Final_file won't have the language folder so the
                # title can be extracted from the mkdocs.yml file
                final_file = os.path.relpath(
                    dest_file, f'{dest_dir}/{file_lang}')

                # Read the file and get the first line as the title
                with open(src_file, "r") as f:
                    content = f.read()

                # Get the title from the mkdocs.yml file,
                # "plugins > i18n > languages > - locale: [lang]
                #   > nav_translations > [nav english title]" section
                title = translated_titles[file_lang].get(
                    f"./{final_file}",
                    self.get_title(content, "--No title--"))

                files_processed.append(final_file)

                item_to_add = {
                    "title": title,
                    "path": final_file,
                    "type": "page",
                    "source": "external",
                    "lang": file_lang
                }

                translate_resp = self.translate_content(
                    content, final_file, file_lang)

                if translate_resp["error_message"] == "":
                    with open(dest_file, "w") as f:
                        f.write(translate_resp["text"])
                    manifest.append(item_to_add)
                else:
                    item_to_add["error"] = translate_resp["error_message"]
                    manifest.append(item_to_add)

        # Save the manifest
        manifest_path = os.path.join(
            os.path.dirname(dest_dir), "docs_manifest.json")
        with open(manifest_path, "w") as f:
            json.dump(manifest, f, indent=2)

        print("")
        print(f"Conversion complete. Manifest saved to {manifest_path}")
        print("")
        if self.errors_happened:
            print("ERROR: Errors happened during the conversion.")
            print("Not all files were translated. Please check the errors")
            print(" above.")
            print("")
            sys.exit(1)


if __name__ == "__main__":
    converter = DocsConverter()
    converter.run()
