let baseUrl = "https://itsm.sgnet.gov.sg/text_search_exact_match.do?sysparm_search=";
 
// Prompt the user for case numbers, each on a new line
let caseNumbersInput = prompt("Enter case numbers separated by new lines:");
 
// Split the input string into an array using the newline character
let caseNumbers = caseNumbersInput.split('\n').map(caseNumber => caseNumber.trim());
 
// Set the delay between opening each URL (in milliseconds)
let delay = 0;
 
// Iterate over each case number
caseNumbers.forEach((caseNumber, index) => {
    // Construct the full URL for each case number
    let url = baseUrl + caseNumber;
    // Open the URL in a new tab with a slight delay between each
    setTimeout(() => {
        window.open(url, '_blank', 'noopener,noreferrer');
    }, delay * index);
});