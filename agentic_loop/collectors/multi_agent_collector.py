from pathlib import Path


REQUIRED_AGENT_FUNCTIONS = {
    "planner_agent.py": "plan_workflow",
    "worker_agent.py": "generate_output",
    "reviewer_agent.py": "review_output",
}


def collect(app_dir: Path, repo_root: Path) -> tuple[bool, str]:
    server_dir = app_dir / "multi-agent-server"
    agents_dir = server_dir / "agents"

    required_paths = [
        agents_dir / "planner_agent.py",
        agents_dir / "worker_agent.py",
        agents_dir / "reviewer_agent.py",
        server_dir / "coordinator.py",
        server_dir / "app.py",
        server_dir / "requirements.txt",
        app_dir / "enrolment-service" / "routes" / "multi_agent_mode.py",
        app_dir / "prompts" / "lab10" / "implementation" / "multi_agent_implementation_prompt.txt",
        app_dir / "prompts" / "lab10" / "review" / "multi_agent_review_prompt.txt",
    ]

    missing = [str(path.relative_to(app_dir)) for path in required_paths if not path.exists()]
    if missing:
        return False, "Multi-agent evidence incomplete. Missing: " + ", ".join(missing)

    coordinator_text = (server_dir / "coordinator.py").read_text(encoding="utf-8")

    missing_calls = [
        func for func in REQUIRED_AGENT_FUNCTIONS.values() if func not in coordinator_text
    ]
    if missing_calls:
        return False, "coordinator.py missing calls to: " + ", ".join(missing_calls)

    return True, (
        "Multi-agent evidence: multi-agent-server/ contains planner_agent.py, worker_agent.py, "
        "reviewer_agent.py, coordinator.py, and app.py; coordinator wires plan_workflow, "
        "generate_output, and review_output into a single workflow."
    )