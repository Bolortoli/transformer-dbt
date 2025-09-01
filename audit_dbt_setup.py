#!/usr/bin/env python3
"""
Static audit for dbt project setup.

This script performs non-invasive checks so it can run without cloud credentials.
It verifies:
- dbt_project.yml and profiles.yml alignment (project name, profile name, targets)
- presence of key directories defined in dbt_project.yml (models, macros, tests, etc.)
- basic YAML structure for models/schema.yml and models/sources.yml
- simple best-practice nudges

Usage:
  python audit_dbt_setup.py

Exit codes:
  0 = OK (no blocking issues found)
  1 = Issues found
"""
from __future__ import annotations
import os
import sys
import json
from typing import Any, Dict, List, Tuple

try:
    import yaml  # type: ignore
except Exception:
    print("ERROR: PyYAML is required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

ROOT = os.path.dirname(os.path.abspath(__file__))

PROBLEMS: List[str] = []
WARNINGS: List[str] = []


def load_yaml(path: str) -> Dict[str, Any]:
    if not os.path.exists(path):
        PROBLEMS.append(f"Missing file: {os.path.relpath(path, ROOT)}")
        return {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}
    except Exception as e:
        PROBLEMS.append(f"Failed to parse YAML: {os.path.relpath(path, ROOT)} ({e})")
        return {}


def check_project_and_profile() -> None:
    project_path = os.path.join(ROOT, "dbt_project.yml")
    profiles_path = os.path.join(ROOT, "profiles.yml")

    project = load_yaml(project_path)
    profiles = load_yaml(profiles_path)

    # Basic existence
    if not project:
        return
    if not profiles:
        return

    # Check project name and profile linkage
    proj_name = project.get("name")
    profile_name = project.get("profile")
    if not proj_name:
        PROBLEMS.append("dbt_project.yml: 'name' is required")
    if not profile_name:
        PROBLEMS.append("dbt_project.yml: 'profile' is required")

    # Profile should exist
    if profile_name and profile_name not in profiles:
        PROBLEMS.append(
            f"profiles.yml: profile '{profile_name}' not found (profiles defined: {list(profiles.keys())})"
        )

    # Targets
    if profile_name and profile_name in profiles:
        prof = profiles[profile_name]
        target = prof.get("target")
        outputs = prof.get("outputs") or {}
        if not outputs:
            PROBLEMS.append(f"profiles.yml: profile '{profile_name}' has no outputs")
        if target and target not in outputs:
            PROBLEMS.append(
                f"profiles.yml: target '{target}' not defined under outputs for profile '{profile_name}'"
            )

        # BigQuery specifics (non-blocking checks)
        for out_name, out in outputs.items():
            if out.get("type") != "bigquery":
                WARNINGS.append(
                    f"profiles.yml: output '{out_name}' type is '{out.get('type')}', expected 'bigquery' for this project"
                )
            if out.get("method") == "service-account":
                keyfile = out.get("keyfile")
                if isinstance(keyfile, str) and keyfile.strip() == "":
                    WARNINGS.append(
                        f"profiles.yml: output '{out_name}' uses service-account but keyfile is empty string; set GOOGLE_APPLICATION_CREDENTIALS or use oauth target"
                    )


def check_paths() -> None:
    project_path = os.path.join(ROOT, "dbt_project.yml")
    project = load_yaml(project_path)
    if not project:
        return
    path_keys = [
        ("model-paths", True),
        ("analysis-paths", False),
        ("test-paths", False),
        ("seed-paths", False),
        ("macro-paths", False),
        ("snapshot-paths", False),
    ]
    for key, required in path_keys:
        paths = project.get(key) or []
        if required and not paths:
            PROBLEMS.append(f"dbt_project.yml: '{key}' missing or empty")
        for p in paths:
            abs_p = os.path.join(ROOT, p)
            if not os.path.isdir(abs_p):
                WARNINGS.append(f"Path '{p}' (from {key}) does not exist yet; create if needed")


def check_models_yaml() -> None:
    schema_yml = os.path.join(ROOT, "models", "schema.yml")
    data = load_yaml(schema_yml)
    if not data:
        return
    if data.get("version") not in (2, "2"):
        WARNINGS.append("models/schema.yml: 'version: 2' is recommended")
    models = data.get("models")
    if not isinstance(models, list):
        PROBLEMS.append("models/schema.yml: 'models' should be a list")
        return
    # Light validation of accepted_values syntax if present
    for m in models:
        cols = (m or {}).get("columns") or []
        for c in cols:
            tests = (c or {}).get("tests") or []
            for t in tests:
                if isinstance(t, dict) and "accepted_values" in t:
                    av = t["accepted_values"]
                    if isinstance(av, dict) and "arguments" in av and "values" not in av:
                        PROBLEMS.append(
                            "models/schema.yml: 'accepted_values' should be 'values: [...]' (not under 'arguments')"
                        )


def check_sources_yaml() -> None:
    sources_yml = os.path.join(ROOT, "models", "sources.yml")
    data = load_yaml(sources_yml)
    if not data:
        return
    if data.get("version") not in (2, "2"):
        WARNINGS.append("models/sources.yml: 'version: 2' is recommended")
    sources = data.get("sources")
    if not isinstance(sources, list) or not sources:
        PROBLEMS.append("models/sources.yml: at least one source should be defined")
        return
    # Suggest database key for BigQuery (non-blocking)
    for s in sources:
        if "database" not in s:
            WARNINGS.append(
                f"models/sources.yml: source '{s.get('name')}' has no 'database' (BigQuery project); explicit database is recommended"
            )


def main() -> int:
    check_project_and_profile()
    check_paths()
    check_models_yaml()
    check_sources_yaml()

    print("DBT SETUP AUDIT REPORT\n========================\n")
    if PROBLEMS:
        print("Blocking issues:")
        for p in PROBLEMS:
            print(f"- [ERROR] {p}")
        print()
    else:
        print("No blocking issues found.\n")

    if WARNINGS:
        print("Advisories:")
        for w in WARNINGS:
            print(f"- [WARN] {w}")
        print()

    # Machine-readable output (optional)
    result = {"problems": PROBLEMS, "warnings": WARNINGS}
    print("JSON:")
    print(json.dumps(result, indent=2))

    return 1 if PROBLEMS else 0


if __name__ == "__main__":
    sys.exit(main())
