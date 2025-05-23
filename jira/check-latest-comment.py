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
    TSEList = [
        "mohammad.rafiq",
        "karishmma",
        "vinotheni",
        "piramilah",
        "taqiuddin",
        "jimi.mirza",
        "Xavier Selvanathan (XTR)",
    ]
    SecTeamList = [
        "Praveen Kumar Reddy (XTR)",
        "Larrie Ng (XTR)",
        "Mikhael Artur Darmakesuma (XTR)",
    ]
    for issue in jira.search_issues(
        'project != CWPEVT and status not in (Closed, "Pending Clarification", Resolved) ORDER BY created DESC',
        maxResults=100,
    ):
        latest_comment = get_latest_comment_object(issue)

        if latest_comment:
            nameToCheck = latest_comment.author.displayName
        else:
            nameToCheck = issue.fields.reporter.displayName

        if (
            nameToCheck not in SecTeamList
            and nameToCheck not in TSEList
            and issue.fields.project.name == "CWPGVT"
        ) or (issue.fields.project.name != "CWPGVT" and nameToCheck not in TSEList):
            print(f'FYA: {issue.key}: "{nameToCheck}"')


if __name__ == "__main__":
    main()
