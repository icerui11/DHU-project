def count_hex_values(data):
    """
    Counts the number of hexadecimal values in a string, ignoring spaces
    and other non-hex characters.
    
    Args:
        data (str): String containing hex data
        
    Returns:
        int: Count of hexadecimal values found
    """
    # Initialize counters and buffers
    hex_count = 0
    current_hex = ""
    
    # Process each character in the input data
    for char in data:
        # Check if the character is a valid hex digit (0-9, a-f, A-F)
        if char.lower() in '0123456789abcdef':
            current_hex += char
            # When we have a complete byte (2 hex digits), count it
            if len(current_hex) == 2:
                hex_count += 1
                current_hex = ""  # Reset for next hex value
        # If we encounter a space or other character while building a hex value
        elif current_hex:
            # If we have a partial hex value (just one digit), it's still valid
            if len(current_hex) == 1:
                # Treat single digit as if it had a leading zero
                hex_count += 1
            current_hex = ""  # Reset for next hex value
    
    # Check if we have a remaining partial hex value at the end
    if current_hex:
        hex_count += 1
        
    return hex_count

# Example usage
if __name__ == "__main__":
    # Get input directly from the user
    print("Enter or paste your hex data:")
    data = input()
    
    # You could also accept multi-line input like this:
    # import sys
    # print("Enter or paste your hex data (press Ctrl+D when finished):")
    # data = sys.stdin.read()
    
    count = count_hex_values(data)
    print(f"Total hexadecimal values found: {count}")