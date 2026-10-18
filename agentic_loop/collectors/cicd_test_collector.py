from pathlib import Path


def collect(app_dir: Path, repo_root: Path) -> tuple[bool, str]:
    post_commit_dir = app_dir / "tests" / "lab11" / "post_commit"
    reports_dir = app_dir / "reports" / "lab11"

    required_paths = [
        post_commit_dir / "test_api_students.py",
        post_commit_dir / "test_token_auth.py",
        reports_dir / "test-results.md",
        reports_dir / "test-audit.jsonl",
    ]

    missing = [str(path.relative_to(app_dir)) for path in required_paths if not path.exists()]
    if missing:
        return False, "CI/CD test evidence incomplete. Missing: " + ", ".join(missing)

    audit_lines = (reports_dir / "test-audit.jsonl").read_text(encoding="utf-8").strip().splitlines()
    if not audit_lines:
        return False, "reports/lab11/test-audit.jsonl is empty. Run the post-commit tests first."

    last_status = "PASS" in audit_lines[-1]

    return True, (
        "CI/CD test evidence: tests/lab11/post_commit/ contains API and token-auth tests; "
        f"reports/lab11/test-results.md and test-audit.jsonl exist "
        f"(latest audit entry status: {'PASS' if last_status else 'FAIL'})."
    )