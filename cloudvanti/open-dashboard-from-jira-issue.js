const inputUrl = prompt("Enter the input string (e.g., t727-p908):");
const parts = inputUrl.split('-');
const prefix = "https://app.cwp2.cloudvanti.com/project-management/";
const firstPart = parts[0];
const transformedUrl = `${prefix}${firstPart}/${inputUrl}`;
window.open(transformedUrl, '_blank');
