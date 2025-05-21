import os
import sys
from jira import JIRA

def main():
    jira_link = os.environ["CVT_JIRA_LINK"]
    print(jira_link)
    jira_pat = os.environ["CVT_JIRA_KEY"]
    jira = JIRA(server=jira_link, token_auth=jira_pat)

if __name__ == "__main__":
    main()
