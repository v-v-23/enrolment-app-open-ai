# MCP Manual Testing — Run Report

## Backend Test (Terminal)

Ran `python tools.py`:

- student_count → {'student_count': 10}
- students_by_subject('ASD101') → 2 students returned (John Smith, Sarah Jones)
- list_project_files → listed project folders correctly
- read_ci_report → returned report.json contents

All 4 tools worked as expected.

## MCP Server Start

Ran `python server.py` — server started successfully:

## UI Testing — MCP Mode ON

Tested at http://localhost:8080, MCP tab.

- Clicked "Get Student Count" → correctly showed student count: 10
- Entered "ASD101", clicked "Run Tool" → correctly showed 2 students

(screenshots below)

## UI Testing — MCP Mode OFF

- Toggled MCP Mode to OFF
- Clicked tool buttons → correctly showed "MCP Mode is OFF. Enable MCP Mode to run MCP tools."

(screenshots below)
