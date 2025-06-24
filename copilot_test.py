#!/usr/bin/env python3
"""
Test file for GitHub Copilot integration with nvim-cmp
"""

import os
import sys
from typing import List, Dict, Optional

# Test 1: Function signature that Copilot should complete
def fibonacci(n: int) -> int:
    """Calculate the nth Fibonacci number"""
    # Start typing here and Copilot should suggest the implementation
    if n <=

# Test 2: Common algorithm pattern
def quicksort(arr: List[int]) -> List[int]:
    """Implement quicksort algorithm"""
    # Type here for Copilot suggesasffastions



# Test 3: Data processing function
def process_data(data: List[Dict]) -> List[Dict]:
    # Copilot should suggest data processing logic

# Test 4: File operations
def read_file_lines(filename: str) -> List[str]:
    # Copilot should suggest file reading implementation

# Test 5: Class definition that Copilot should complete
class Calculator:
    """Simple calculator class"""

    def __init__(self):
        # Copilot should suggest initialization

    def add(self, a: float, b: float) -> float:
        # Simple addition - Copilot should suggest return a + b

    def multiply(self, a: float, b: float) -> float:
        # Copilot should suggest: return a * b

# Test 6: Comment-driven development
# Function to sort a list of dictionaries by a specific key
def sort_by_key(data, key):
    # Copilot should suggest the sorting implementation

# Test 7: Web scraping function
def fetch_url_content(url: str) -> str:
    # Copilot should suggest requests/urllib implementation

# Test API call
import requests

def fetch_user_data(user_id):
    """Fetch user data from API"""
    # Copilot should suggest API implementation

if __name__ == "__main__":
    # Copilot should suggest main function logic
    pass
