import os
import subprocess
from translate_ai_module import translate


def get_uncommitted_md_files(repo_path):
    """
    Get the list of uncommitted .md files in the mkdocs_root/en directory.
    """
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True
        )
        files = []
        for line in result.stdout.splitlines():
            # Matches 'M ', 'A ', '?? ' etc. followed by the path
            if line.strip() and ".md" in line:
                path = line.strip().split()[-1]
                if path.startswith("mkdocs_root/en/"):
                    files.append(path)
        return files
    except Exception as e:
        print(f"Error getting uncommitted files: {e}")
        return []


def translate_file(repo_path, file_path):
    """
    Translate a single file and save it to the corresponding /es/ path.
    """
    src_path = os.path.join(repo_path, file_path)
    dest_path = src_path.replace("/mkdocs_root/en/", "/mkdocs_root/es/")

    print(f"Processing: {file_path}")

    if not os.path.exists(src_path):
        print(f"  Source file not found: {src_path}")
        return

    with open(src_path, "r", encoding="utf-8") as f:
        content = f.read()

    print("  Translating content...")
    result = translate(content, dest="es", src="en")

    if result.get("error"):
        print(f"  Error translating {file_path}: {result['error_message']}")
        return

    # Ensure destination directory exists
    os.makedirs(os.path.dirname(dest_path), exist_ok=True)

    with open(dest_path, "w", encoding="utf-8") as f:
        f.write(result["text"])

    print(f"  Saved to: {dest_path}")


def main():
    # Use absolute paths or relative to the script location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    repo_path = os.path.join(project_root, "genericsuite-basecamp")

    # Load .env from project root if it exists
    env_path = os.path.join(project_root, ".env")
    if os.path.exists(env_path):
        print(f"Loading environment from {env_path}")
        with open(env_path, "r") as f:
            for line in f:
                if line.strip() and not line.startswith("#") and "=" in line:
                    key, value = line.strip().split("=", 1)
                    os.environ[key] = value

    print(f"Repo path: {repo_path}")

    files_pk = get_uncommitted_md_files(repo_path)

    if not files_pk:
        print("No uncommitted documentation files found in mkdocs_root/en.")
        return

    print(f"Found {len(files_pk)} files to translate.")
    for file_path in files_pk:
        translate_file(repo_path, file_path)


if __name__ == "__main__":
    main()
