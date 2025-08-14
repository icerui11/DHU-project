import sys

def text_to_char(input_text_file, output_char_file):
    with open(input_text_file, 'r') as infile, open(output_char_file, 'w') as outfile:
        for line in infile:
            # Convert each character to its ASCII value
            ascii_values = [str(ord(char)) for char in line]
            outfile.write(' '.join(ascii_values) + '\n')
    
    print(f"Converted {input_text_file} to character format in {output_char_file}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python text_converter.py [input_file] [output_file]")
    else:
        input_file = sys.argv[1]
        output_file = sys.argv[2]
        text_to_char(input_file, output_file)