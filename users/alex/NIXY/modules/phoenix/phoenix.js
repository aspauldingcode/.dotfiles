//Phoenix.notify("Phoenix config loading")

Phoenix.set({
  daemon: true,
  openAtLogin: true
})
// Import the Phoenix library
const { App, Screen, Modal } = Phoenix;

// Function to display modal window with "Hello?" prompt
function displayHelloModal() {
    // Get the main screen frame
    const screenFrame = Screen.main().flippedVisibleFrame();

    // Create a new modal
    const modal = new Modal();

    // Configure the modal
    modal.isInput = true; // Enable input mode
    modal.appearance = 'light'; // Set appearance to light
    modal.origin = {
        x: screenFrame.width / 2 - modal.frame().width / 2,
        y: screenFrame.height / 2 - modal.frame().height / 2,
    }; // Position modal in the middle of the screen
    modal.text = "Hello?"; // Set the prompt text

    // Event handler for text changes
    modal.textDidChange = (value) => {
        console.log('Text did change:', value);
    };

    // Event handler for text commit
    modal.textDidCommit = (value, action) => {
        console.log('Text did commit:', value, action);
    };

    // Show the modal
    modal.show();
}

// Main function
function main() {
    displayHelloModal();
}

main();
Phoenix.notify("Loaded!")
