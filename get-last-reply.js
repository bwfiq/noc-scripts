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

      // Find the parent with class "h-card h-card_md h-card_comments"
      let hCardParent = foundElement;
      while (hCardParent && (!hCardParent.classList || !hCardParent.classList.contains("h-card") || !hCardParent.classList.contains("h-card_md") || !hCardParent.classList.contains("h-card_comments"))) {
        hCardParent = hCardParent.parentElement;
      }

      if (!hCardParent) {
        console.error("Error: Could not find parent element with class 'h-card h-card_md h-card_comments'.");
        alert("Error: Could not find parent element with class 'h-card h-card_md h-card_comments'.");
        return;
      }

      console.log("Found hCardParent:", hCardParent);

      // Recursive function to find element with class date-calendar
      function findDateCalendar(element) {
        if (!element) {
          return null;
        }

        if (element.classList && element.classList.contains("date-calendar")) {
          console.log("Found 'date-calendar' element:", element);
          return element;
          return element;
        }

        for (let i = 0; i < element.children.length; i++) {
          const found = findDateCalendar(element.children[i]);
          if (found) {
            return found;
          }
        }
        return null;
      }

      // Recursive function to find element with class "sn-widget-textblock-body sn-widget-textblock-body_formatted"
      function findLastReplyElement(element) {
        if (!element) {
          return null;
        }

        if (element.classList && element.classList.contains("sn-widget-textblock-body") && element.classList.contains("sn-widget-textblock-body_formatted")) {
          console.log("Found 'sn-widget-textblock-body sn-widget-textblock-body_formatted' element:", element);
          return element;
        }

        for (let i = 0; i < element.children.length; i++) {
          const found = findLastReplyElement(element.children[i]);
          if (found) {
            return found;
          }
        }

        return null;
      }

      const dateCalendarElement = findDateCalendar(hCardParent);
      const lastReplyElement = findLastReplyElement(hCardParent);

      let foundTimestamp = dateCalendarElement ? dateCalendarElement.textContent.trim() : "Timestamp not found";
      let foundLastReply = "Last Reply not found"; // Default value if not found

      if (lastReplyElement) {
          console.log("Attempting to get text content from the shadow DOM");
          const shadowRoot = lastReplyElement.shadowRoot;

          if (shadowRoot) {
              console.log("Shadow DOM found");
              const divElement = shadowRoot.querySelector("div");
              if(divElement) {
                console.log("Div element inside shadow DOM found");
                foundLastReply = ""; // Initialize as empty string
                for (let i = 0; i < divElement.children.length; i++) { // Go through each child (p elements)
                    foundLastReply += divElement.children[i].textContent.trim() + " "; //Concat all paragraph elements
                }
                foundLastReply = foundLastReply.trim(); // Remove trailing space
              } else {
                console.log("Div element not found inside shadow DOM");
              }
          } else {
              console.log("Shadow DOM not found.  Attempting textContent from the original element.")
              foundLastReply = lastReplyElement.textContent.trim(); //Fallback if there is no shadow DOM
          }

      }

      console.log("Timestamp:", foundTimestamp);
      console.log("Last Reply:", foundLastReply);

      alert("Timestamp: " + foundTimestamp + "\nLast Reply: " + foundLastReply);
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