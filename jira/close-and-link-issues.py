import os


def cat_file_from_env(env_var_name):
    file_path = os.environ[env_var_name]
    print(parse_file_path_as_text(file_path))


def parse_file_path_as_text(file_path):
    result = ""
    with open(file_path, "r") as f:
        for line in f:
            result += line
    return result


if __name__ == "__main__":
    cat_file_from_env("CWP_JIRA_LINK_FILE")
    cat_file_from_env("CWP_JIRA_ACCESS_KEY_FILE")
