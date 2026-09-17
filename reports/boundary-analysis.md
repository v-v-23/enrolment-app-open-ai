# MCP Tool Boundary Analysis

## Tool Boundaries

| Tool                | Responsibility               | Not Responsible For          |
| ------------------- | ---------------------------- | ---------------------------- |
| student_count       | Count student records        | Explaining enrollment policy |
| students_by_subject | Retrieve subject enrollments | Predicting performance       |
| project_files       | List application files       | Judging code quality         |
| ci_report           | Read CI evidence             | Deciding release approval    |

## Decision: ACCEPTED

All tool boundaries are explicit and appropriate for controlled access.
