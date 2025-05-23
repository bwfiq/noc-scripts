import os
import sys
from jira import JIRA


def get_latest_comment_object(issue):
    comments = issue.fields.comment.comments
    if not comments:
        return None
    return comments[-1]


def main():
    jira_link = os.environ["CVT_JIRA_LINK"]
    jira_pat = os.environ["CVT_JIRA_KEY"]
    jira = JIRA(server=jira_link, token_auth=jira_pat)
    # Define list of TSE
    TSEList = [
        "mohammad.rafiq",
        "karishmma",
        "vinotheni",
        "piramilah",
        "taqiuddin",
        "jimi.mirza",
        "Xavier Selvanathan (XTR)",
    ]
    # Get all issues that are not closed
    for issue in jira.search_issues(
        'project != CWPEVT and status not in (Closed, "Pending Clarification", Resolved)  ORDER BY created DESC',
        maxResults=100,
    ):
        latest_comment = get_latest_comment_object(issue)
        if latest_comment and latest_comment.author.displayName not in TSEList:
            print(f"{issue.key}: {latest_comment.author.displayName}")
    # def empty list
    # For each:
    # Check who made the last comment
    # If not TSE, add to list
    # print list


if __name__ == "__main__":
    main()
