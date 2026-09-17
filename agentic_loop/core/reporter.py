def print_prompt_map(mapping: dict[str, str]):
  print("PROMPT PATH MAP")
  for label, path in mapping.items():
    print(f"- {label}: {path}")


def print_menu() -> None:
  print("\nOptions:")
  print("  1 - DB")
  print("  2 - Endpoints")
  print("  3 - Architecture")
  print("  4 - DevOps")
  print("  5 - MCP")  # Add this line
  print("  0 - Exit")

def print_result(title: str, text: str) -> None:
  print()
  print(f"RUNNING: {title}")
  print(text)