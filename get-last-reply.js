javascript:(function() {
  try {
    console.log("Starting script...");

    const hCardWrapper = document.querySelector('.h-card-wrapper.activities-form');
    console.log("Attempting to find hCardWrapper element.");

    if (!hCardWrapper) {
      console.error("Error: Element with class '.h-card-wrapper.activities-form' not found.");
      alert("Error: Element with class '.h-card-wrapper.activities-form' not found.");
      console.log("hCardWrapper not found. Exiting.");
      return;
    }

    console.log("hCardWrapper found:", hCardWrapper);

    const listElements = hCardWrapper.querySelectorAll('ul > li');
    console.log("Attempting to find list elements inside hCardWrapper.");

    if (!listElements || listElements.length === 0) {
      console.error("Error: No 'ul > li' elements found inside the h-card-wrapper.");
      alert("Error: No 'ul > li' elements found inside the h-card-wrapper.");
      console.log("No list elements found. Exiting.");
      return;
    }

    console.log("List elements found:", listElements);

    let foundElement = null;
    let foundText = null;

    console.log("Starting loop through list elements...");

    for (let i = 0; i < listElements.length; i++) {
      let currentListElement = listElements[i];
      console.log("Processing list element at index:", i, currentListElement);

      // Recursive function to find the element
      function findCreatedByElement(element) {
        if (!element) {
          return null;
        }

        if (element.classList && element.classList.contains("sn-card-component-createdby")) {
          console.log("Found 'sn-card-component-createdby' element:", element);
          return element;
        }

        for (let j = 0; j < element.children.length; j++) {
          const found = findCreatedByElement(element.children[j]);
          if (found) {
            return found;
          }
        }

        return null; // Not found in this branch
      }

      const createdByElement = findCreatedByElement(currentListElement);

      if (createdByElement) {
        const textContent = createdByElement.textContent.trim().toLowerCase();
        console.log("'sn-card-component-createdby' element found. Text content:", textContent);

        if (textContent !== "system") {
          foundElement = createdByElement;
          foundText = textContent;
          console.log("Text content is not 'system'. Element found.");
          break; // Exit the loop
        } else {
          console.log("Text content is 'system'. Continuing search in next list item.");
        }
      } else {
        console.log("'sn-card-component-createdby' element NOT found in this list item.");
      }
    }

    console.log("Loop finished.");

    if (foundElement) {
      console.log("Element with class 'sn-card-component-createdby' found. Text:", foundText);
      alert("Element with class 'sn-card-component-createdby' found: " + foundText);
    } else {
      console.log("No element with class 'sn-card-component-createdby' found with text not equal to 'system'.");
      alert("No element with class 'sn-card-component-createdby' found with text not equal to 'system'.");
    }

    console.log("Script completed successfully.");

  } catch (error) {
    console.error("An error occurred:", error);
    alert("An error occurred: " + error.message);
    console.log("Script terminated with an error.");
  }
})();