import os
import sys
from jira import JIRA


def parse_file_path_as_text(file_path):
    result = ""
    with open(file_path, "r") as f:
        for line in f:
            result += line
    return result


def extract_ticket_numbers(url_list):
    ticket_numbers = []
    for url in url_list:
        ticket_numbers.append(url.rsplit("/", 1)[-1])
    return ticket_numbers


def process_issue(jira, issue_key):
    """Processes a single Jira issue, asking the user for action."""
    try:
        issue = jira.issue(issue_key)
        transitions = jira.transitions(issue)
        available_transitions = [(t["id"], t["name"]) for t in transitions]

        print(f"\nIssue: {issue_key} - {issue.fields.summary}")  # Print issue summary
        print("Available Transitions:")
        for transition_id, transition_name in available_transitions:
            print(f"  {transition_id}: {transition_name}")

        while True:
            action = (
                input(
                    f"Enter transition ID to apply to {issue_key} (or 'next' to skip): "
                )
                .strip()
                .lower()
            )

            if action == "next":
                print(f"Skipping {issue_key}.")
                return  # Move to the next issue

            try:
                transition_id = int(action)
                if any(str(transition_id) == t_id for t_id, _ in available_transitions):
                    # TODO: Apply the transition
                    print(
                        f"Transitioned {issue_key} to {next((name for id, name in available_transitions if str(id) == str(transition_id)), None)}."
                    )
                    break  # Exit the loop after successful transition
                else:
                    print(
                        "Invalid transition ID. Please choose from the list above or type 'next'."
                    )
            except ValueError:
                print("Invalid input. Please enter a transition ID or 'next'.")
    except Exception as e:
        print(f"Error processing issue {issue_key}: {e}")


def main():
    jira_link = parse_file_path_as_text(os.environ["CWP_JIRA_LINK_FILE"])
    jira_pat = parse_file_path_as_text(os.environ["CWP_JIRA_ACCESS_KEY_FILE"])
    jira = JIRA(server=jira_link, token_auth=jira_pat)

    urls = []
    print("Input URLs separated by a newline (press Enter twice to finish):")
    while True:
        line = sys.stdin.readline().strip()
        if not line:
            break
        urls.append(line)

    extracted_tickets = extract_ticket_numbers(urls)

    print("Processing issues...")
    for issue_key in extracted_tickets:
        process_issue(jira, issue_key)


if __name__ == "__main__":
    main()
