import tkinter as tk
from tkinter import simpledialog

def prompt_for_display():
    root = tk.Tk()
    root.withdraw()  # Hide the main window
    display_id = simpledialog.askstring("Display Identification", "What display is this?")
    print(display_id)  # Output the result to stdout

if __name__ == "__main__":
    prompt_for_display()