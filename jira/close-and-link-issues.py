import os
from jira import JIRA


def parse_file_path_as_text(file_path):
    result = ""
    with open(file_path, "r") as f:
        for line in f:
            result += line
    return result


if __name__ == "__main__":
    jira_link = parse_file_path_as_text(os.environ["CWP_JIRA_LINK_FILE"])
    jira_pat = parse_file_path_as_text(os.environ["CWP_JIRA_ACCESS_KEY_FILE"])
    jira = JIRA(server=jira_link, token_auth=jira_pat)
    issue = jira.issue("CWP1330991-9")
    print(issue.fields.summary)
