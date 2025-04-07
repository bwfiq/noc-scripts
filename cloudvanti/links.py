import sys


def transform_codes(input_string):
    """
    Transforms a list of tenant and project codes from a string
    into URLs in the format specified.

    Args:
      input_string: A string containing tenant/project codes separated by newlines.

    Returns:
      A list of transformed URLs.
    """
    urls = []
    for code in input_string.strip().splitlines():
        code = code.strip()
        if not code:
            continue  # Skip empty lines
        try:
            parts = code.split("-")
            if len(parts) != 2:
                print(f"Warning: Invalid code format '{code}'. Skipping.")
                continue

            tenant_project_code = code  # Keep the original format
            tenant_code = parts[0]
            # Extract tXXX and pXXX parts (robust handling)
            tenant_prefix = tenant_code[:1]
            tenant_number = tenant_code[1:]
            project_code = parts[1]

            if not (
                tenant_prefix == "t"
                and tenant_number.isdigit()
                and project_code.startswith("p")
                and project_code[1:].isdigit()
            ):
                print(f"Warning: Invalid code format '{code}'. Skipping.")
                continue

            url = f"https://app.cwp2.cloudvanti.com/project-management/{tenant_code}/{tenant_project_code}/dashboard"
            urls.append(url)

        except (IndexError, ValueError) as e:
            print(f"Warning: Invalid code format '{code}'. Skipping. Error: {e}")
            continue
    return urls


if __name__ == "__main__":
    input_lines = []
    print("Enter tenant/project codes (tXXX-pXXX).  Press Enter twice to finish:")
    while True:
        line = sys.stdin.readline().strip()
        if not line:  # Empty line means end of input
            if not input_lines:  # if no input was provided
                break
            else:
                break  # Two consecutive empty lines ends input
        input_lines.append(line)

    transformed_urls = transform_codes(
        "\n".join(input_lines)
    )  # Join lines with newline for processing

    for url in transformed_urls:
        print(url)
