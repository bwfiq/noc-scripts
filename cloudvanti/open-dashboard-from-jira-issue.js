function transformAndOpenLink(inputString) {
  // 1. Remove characters after the hyphen (including the hyphen itself)
  const part1 = inputString.split('-')[0];

  // 2. Split the remaining string before the "P"
  const parts = part1.split('P');
  const tPart = parts[0]; // Example: T591
  const pPart = parts[1]; // Example: 830

  // 3. Construct the final URL
  const transformedUrl = `app.cwp2.cloudvanti.com/project-management/${tPart}/${tPart}-P${pPart}`;

  // 4. Open the URL in a new tab
  window.open(transformedUrl, '_blank');
}


// Use a browser prompt to get the input
const userInput = prompt("Enter the string (e.g., T591P830-58):");

if (userInput) { // Check if the user entered anything and didn't cancel.
  transformAndOpenLink(userInput); // Call the function that transforms AND opens the link
  // You can also choose to give a confirmation alert.
  // alert("Link opened in a new tab!");
} else {
  alert("Input cancelled or no input provided.");
}
