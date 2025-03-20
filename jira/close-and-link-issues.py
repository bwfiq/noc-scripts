import os
import sys
from time import clock_settime
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


def close_and_link_issues(jira, issues, linkedIssue):
    commentText = ""
    for issueText in issues:
        # jira.add_comment(issue, commentText)
        issue = jira.issue(issueText)
        transitions = jira.transitions(issue)
        print([(t["id"], t["name"]) for t in transitions])


if __name__ == "__main__":
    jira_link = parse_file_path_as_text(os.environ["CWP_JIRA_LINK_FILE"])
    jira_pat = parse_file_path_as_text(os.environ["CWP_JIRA_ACCESS_KEY_FILE"])
    jira = JIRA(server=jira_link, token_auth=jira_pat)

    urls = []
    print("Input URLs separated by a newline:")
    while True:
        line = sys.stdin.readline().strip()
        if not line:  # check for empty
            break
        urls.append(line)

    extracted_tickets = extract_ticket_numbers(urls)
    print("Finding transitions...")
    close_and_link_issues(jira, extracted_tickets, "")
