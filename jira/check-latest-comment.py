#! /usr/bin/env python

import os
import sys
import json  # Import the json module
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


def load_tse_list(filepath="tse_list.json"):
    """Loads the TSE list from a JSON file.

    Args:
        filepath: The path to the JSON file.  Defaults to "tse_list.json".

    Returns:
        A list of TSE names, or an empty list if the file doesn't exist or
        contains invalid data.
    """
    try:
        with open(filepath, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"TSE list file not found at {filepath}.  Using an empty list.")
        return []
    except json.JSONDecodeError:
        print(f"Error decoding JSON from {filepath}.  Using an empty list.")
        return []


def main():
    jira = JIRA(
        server=os.environ["CVT_JIRA_LINK"], token_auth=os.environ["CVT_JIRA_KEY"]
    )
    # Load the TSE list from a JSON file
    TSEList = load_tse_list()
    check_issues(jira, TSEList)


if __name__ == "__main__":
    main()
