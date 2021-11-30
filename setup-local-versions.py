#!/usr/bin/python3

from dataclasses import dataclass
from pathlib import Path
import os
import re
import subprocess
import sys

BUILD_DIR = Path("/build")
APPLICATION_SERVICES_DIR = BUILD_DIR / "application-services"
ANDROID_COMPONENTS_DIR = BUILD_DIR / "android-components"
FENIX_DIR = BUILD_DIR / "fenix"

@dataclass
class GitCommits:
    application_services: str
    android_components: str
    fenix: str

def main():
    git_commits = calc_git_commits()
    replace_line_with_regex(
        APPLICATION_SERVICES_DIR / '.buildconfig-android.yml',
        r'(\s*)libraryVersion: [\w.]+',
        f'\\1libraryVersion: {git_commits.application_services}'
    )
    replace_line_with_regex(
        ANDROID_COMPONENTS_DIR / 'buildSrc/src/main/java/Dependencies.kt',
        r'(\s*)const val mozilla_appservices = "[\w.]+"',
        f'\\1const val mozilla_appservices = "{git_commits.application_services}"'
    )
    replace_line_with_regex(
        ANDROID_COMPONENTS_DIR / '.buildconfig.yml',
        r'(\s*)componentsVersion: [\w.]+',
        f'\\1componentsVersion: {git_commits.android_components}'
    )
    replace_line_with_regex(
        FENIX_DIR / 'buildSrc/src/main/java/AndroidComponents.kt',
        r'(\s*)const val VERSION = "[\w.]+"',
        f'\\1const val VERSION = "{git_commits.android_components}"'
    )


def calc_git_commits():
    # map fields of GitCommits to git repo directories
    dir_map = {
        'application_services': APPLICATION_SERVICES_DIR,
        'android_components': ANDROID_COMPONENTS_DIR,
        'fenix': FENIX_DIR,
    }
    commit_map = {
        name: subprocess.check_output(["git", "rev-parse", "--short", 'HEAD'], encoding="utf8", cwd=directory).strip()
        for name, directory in dir_map.items()
    }
    return GitCommits(**commit_map)

def replace_line_with_regex(path, pattern, repl):
    with open(path) as f:
        contents = f.read()
    new_contents, count = re.subn(f'^{pattern}$', repl, contents, 0, re.MULTILINE)
    if count != 1:
        print(f"Error replacing version line for {path.name}")
        sys.exit()

    print(f'replacing versions in {path}')
    with open(path, 'w') as f:
        f.write(new_contents)

if __name__ == '__main__':
    main()
