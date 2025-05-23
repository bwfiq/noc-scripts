import os
import sys
from jira import JIRA


def main():
    jira_link = os.environ["CVT_JIRA_LINK"]
    jira_pat = os.environ["CVT_JIRA_KEY"]
    jira = JIRA(server=jira_link, token_auth=jira_pat)
    # Define list of TSE
    # Get all issues that are not closed
    # def empty list
    # For each:
    # Check who made the last comment
    # If not TSE, add to list
    # print list


if __name__ == "__main__":
    main()
