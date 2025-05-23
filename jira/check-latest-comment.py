import os
import sys
from jira import JIRA


def get_members_recursive(obj, indent=0):
    """
    Recursively prints attributes and methods of an object, including class members.

    Args:
        obj: The object to inspect.
        indent: The indentation level for the output.
    """
    indent_str = "  " * indent
    print(
        f"{indent_str}Attributes of {type(obj).__name__}:"
    )  # Use type(obj).__name__ to display class name

    for item in dir(obj):
        if not item.startswith("__"):
            try:
                attribute = getattr(obj, item)
                if callable(attribute):
                    print(f"{indent_str}  {item}: <method>")
                elif isinstance(attribute, type):  # Check if it's a class (type object)
                    print(f"{indent_str}  {item}: <class {attribute.__name__}>")
                    # Recursive call for nested classes
                    get_members_recursive(
                        attribute, indent + 1
                    )  # Pass the class itself
                else:
                    print(f"{indent_str}  {item}: {attribute}")
            except AttributeError:
                print(f"{indent_str}  {item}: (Unable to access)")


def get_name_to_check(issue):
    latest_comment = get_latest_comment_object(issue)
    if latest_comment:
        print("==================")
        get_members_recursive(latest_comment)
        nameToCheck = latest_comment.author.displayName
    else:
        nameToCheck = issue.fields.reporter.displayName
    return nameToCheck


def get_latest_comment_object(issue):
    comments = issue.fields.comment.comments
    if not comments:
        return None
    return comments[-1]


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
    ]
    SecTeamList = [
        "Praveen Kumar Reddy (XTR)",
        "Larrie Ng (XTR)",
        "Mikhael Artur Darmakesuma (XTR)",
        "Kanimozhi Nallatamby (XTR)",
    ]
    for issue in jira.search_issues(
        'project != CWPEVT and status not in (Closed, "Pending Clarification", Resolved) ORDER BY created DESC',
        maxResults=10,
    ):
        nameToCheck = get_name_to_check(issue)
        if (
            nameToCheck not in SecTeamList
            and nameToCheck not in TSEList
            and issue.fields.project.name == "CWPGVT"
        ) or (issue.fields.project.name != "CWPGVT" and nameToCheck not in TSEList):
            print(f'FYA: {issue.key}: "{nameToCheck}"')


if __name__ == "__main__":
    main()
