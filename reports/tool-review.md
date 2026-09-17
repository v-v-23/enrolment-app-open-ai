# MCP Tool Review

## Risk Identified

File tool (project_files) could expose sensitive paths outside workspace.

## Correction Applied

Added path validation in tools.py to restrict access to app directory only.

## Retest

Re-run MCP validation after path restriction update.
