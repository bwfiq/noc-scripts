#! /usr/bin/env python

import os
import sys
from jira import JIRA


def check_issues(jira, list):
    noIssues = True
    for issue in jira.search_issues(
        'project != CWPEVT and status not in (Closed, "Pending Clarification", Resolved) ORDER BY created DESC',
        maxResults=100,
    ):
        nameToCheck = get_name_to_check(jira, issue)
        if nameToCheck not in list:
            noIssues = False
            print(f'{os.environ["CVT_JIRA_LINK"]}/browse/{issue.key}: "{nameToCheck}"')
    if noIssues:
        print("Found no issues.")


def get_name_to_check(jira, issue):
    latest_comment = get_latest_comment_object(jira, issue)
    if latest_comment:
        nameToCheck = latest_comment.author.displayName
    else:
        nameToCheck = issue.fields.reporter.displayName
    return nameToCheck


def get_latest_comment_object(jira, issue, excludeInternal=True):
    comments = jira.comments(issue, expand="properties")
    if not comments:
        return None
    for comment in reversed(comments):  # Iterate backwards to find the *latest* comment
        if not excludeInternal:
            return comment
        isInternal = False
        # sd.public.comment is "internal", True means internal
        # sd.allow.public.comment is "allow", True means not internal
        for property in comment.properties:
            if property.key == "sd.public.comment" and hasattr(
                property.value, "internal"
            ):
                isInternal = property.value.internal
            elif property.key == "sd.allow.public.comment" and hasattr(
                property.value, "allow"
            ):
                isInternal = not property.value.allow
        if not isInternal:
            return comment
    # If all comments are internal?
    return None


def main():
    jira = JIRA(
        server=os.environ["CVT_JIRA_LINK"], token_auth=os.environ["CVT_JIRA_KEY"]
    )
    TSEList = [
        "mohammad.rafiq",
        "karishmma",
        "vinotheni",
        "piramilah",
        "taqiuddin",
        "jimi.mirza",
        "Xavier Selvanathan (XTR)",
        "Zhao Bozhi (XTR)",
        "C. Egaatharshinee (XTR)",
        "Nazirul Bin Zailani (XTR)",
        "S. Regan (XTR)",
        "aina",
        "jeganathan.naigam",
        "Wilson Lim (XTR)",
        "Hadif Aiman Khalid (XTR)",
        "linda.micheal",
        "Praveen Kumar Reddy (XTR)",
        "Larrie Ng (XTR)",
        "Mikhael Artur Darmakesuma (XTR)",
        "Kanimozhi Nallatamby (XTR)",
        "Ravishankar CHANDRASHEKAR (GVT)",
    ]
    check_issues(jira, TSEList)


if __name__ == "__main__":
    main()
