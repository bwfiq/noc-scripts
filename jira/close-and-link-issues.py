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


def link_issue(jira, issue_key, link_issue_key, comment_text, link_type="relates to"):
    """Links two issues with a comment, only if the link doesn't exist."""
    try:
        issue = jira.issue(issue_key)
        # Check if the link already exists
        existing_links = issue.fields.issuelinks
        link_exists = False
        for link in existing_links:
            if (
                hasattr(link, "inwardIssue") and link.inwardIssue.key == link_issue_key
            ) or (
                hasattr(link, "outwardIssue")
                and link.outwardIssue.key == link_issue_key
            ):
                link_exists = True
                break

        if not link_exists:
            # Check if the comment already exists
            comment_exists = False
            for comment in jira.comments(issue):
                if comment.body == comment_text:
                    comment_exists = True
                    break

            if not comment_exists:
                # Post the comment to the issue separately
                jira.add_comment(issue, comment_text)
                # Create the link *without* the comment
                jira.create_issue_link(link_type, issue_key, link_issue_key)
                print(f"Linked {issue_key} to {link_issue_key} and added comment.")
            else:
                print(f"Comment already exists on {issue_key}. Skipping commenting.")
        else:
            print(
                f"Link already exists between {issue_key} and {link_issue_key}. Skipping linking."
            )

    except Exception as e:
        print(f"Error linking {issue_key} to {link_issue_key}: {e}")


def close_issue(jira, issue_key, close_transition_name="Cancel"):
    """Closes an issue if it's not already closed."""
    try:
        issue = jira.issue(issue_key)
        # Check if the issue is already closed
        is_closed = issue.fields.status.name in [
            "Closed",
            "Resolved",
            "Done",
        ]  # Adjust status names as needed

        if is_closed:
            print(f"Issue {issue_key} is already closed. Skipping.")
            return

        transitions = jira.transitions(issue)
        available_transitions = [(t["id"], t["name"]) for t in transitions]

        # Find the close transition ID
        close_transition_id = None
        for transition_id, transition_name in available_transitions:
            if transition_name == close_transition_name:
                close_transition_id = transition_id
                break

        if close_transition_id:
            print(
                f"Applying transition '{close_transition_name}' to issue {issue_key}."
            )
            jira.transition_issue(issue, close_transition_id)
            print(f"Transitioned {issue_key} to {close_transition_name}.")
        else:
            print(
                f"Transition '{close_transition_name}' not found for issue {issue_key}. Skipping closing."
            )

    except Exception as e:
        print(f"Error closing issue {issue_key}: {e}")


def process_issue(jira, issue_key, link_issue_key):
    """Processes a single Jira issue: linking and closing."""
    try:
        issue = jira.issue(issue_key)  # Fetch the issue once
        print(f"\nIssue: {issue_key} - {issue.fields.summary}")  # Print issue summary

        comment_text = f"Hi,\nWe will close this ticket and follow up on this ticket {link_issue_key} instead.\n\nThank you for your understanding."

        link_issue(jira, issue_key, link_issue_key, comment_text)
        close_issue(jira, issue_key)  # Use default "Cancel" transition

    except Exception as e:
        print(f"Error processing issue {issue_key}: {e}")


def main():
    jira_link = parse_file_path_as_text(os.environ["CWP_JIRA_LINK_FILE"])
    jira_pat = parse_file_path_as_text(os.environ["CWP_JIRA_ACCESS_KEY_FILE"])
    jira = JIRA(server=jira_link, token_auth=jira_pat)

    link_issue_key = input("Enter the issue key to link to: ").strip()
    if not link_issue_key:
        print("Issue key is required. Exiting.")
        return

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
        process_issue(jira, issue_key, link_issue_key)


if __name__ == "__main__":
    main()
