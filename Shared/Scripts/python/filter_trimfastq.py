#!/usr/bin/env python3
"""
Filter script to remove progress messages from trimfastq.py output
and keep only valid FASTQ content.
Compatible with Python 3+
"""

import sys
import re

def is_fastq_line(line):
    """Check if a line is a valid FASTQ line (starts with @, +, or is a sequence/quality line)"""
    line = line.strip()
    if not line:
        return False
    
    # FASTQ format: @ID, +ID, sequence, or quality scores
    if line.startswith('@') or line.startswith('+'):
        return True
    
    # Sequence or quality line (should contain only ATCGN for DNA or valid quality scores)
    if re.match(r'^[ATCGN]+$', line, re.IGNORECASE):
        return True
    
    # Quality scores (ASCII characters, typically ! to ~)
    if re.match(r'^[!-~]+$', line):
        return True
    
    return False

def filter_trimfastq_output(input_file, output_file):
    """Filter trimfastq.py output to keep only FASTQ content"""
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            if is_fastq_line(line):
                outfile.write(line)
            # Skip progress messages and other non-FASTQ content

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python filter_trimfastq.py <input_file> <output_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    filter_trimfastq_output(input_file, output_file)
    print("Filtered {} -> {}".format(input_file, output_file))
