#!/usr/bin/env python3

import csv
import re
import os

input_output_file = 'assets_temp.csv'

# Function to process 'BLDG_RM_NR' and extract building, room, space, and floor
def process_bldg_rm_nr(bldg_rm_nr):
    bldg = '978' if '978' in bldg_rm_nr else ''
    rm = re.sub(r'[^0-9]', '', bldg_rm_nr[4:])
    space = re.search(r'[A-Za-z]', bldg_rm_nr)
    space = space.group(0) if space else ''
    floor = ''
    for char in bldg_rm_nr:
        if char.isdigit() and char in ['3', '4']:
            floor = char
            break
    return bldg, rm, space, floor

# Read the CSV file and modify data
with open(input_output_file, mode='r+', newline='') as file:
    reader = csv.reader(file)
    writer = csv.writer(file)

    # Read the header
    header = next(reader)
    header.extend(['BLDG', 'RM', 'SPACE', 'FLOOR', 'ASSIGNED_USER'])

    # Process each row
    modified_rows = []
    for row in reader:
        bldg_rm_nr = row[header.index('BLDG_RM_NR')]
        bldg, rm, space, floor = process_bldg_rm_nr(bldg_rm_nr)
        row.extend([bldg, rm, space, floor, ''])  # Assuming 'ASSIGNED_USER' is blank
        modified_rows.append(row)

    # Move to the beginning of the file
    file.seek(0)

    # Write the modified data to the CSV file
    writer.writerow(header)
    writer.writerows(modified_rows)

    # Truncate the file to remove any remaining rows
    file.truncate()

# Calculate total file size
file_size = os.path.getsize(input_output_file)

# Convert file size to human-readable format
def convert_size(size_in_bytes):
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_in_bytes < 1024.0:
            return f"{size_in_bytes:.2f} {unit}"
        size_in_bytes /= 1024.0

# Function to print text in a box
def print_in_box(text):
    lines = text.split('\n')
    max_length = max(len(line) for line in lines)
    border = '+' + '-' * (max_length + 2) + '+'
    print()
    print(border)
    for line in lines:
        print(f"| {line.ljust(max_length)} |")
    print(border)

# Print formatted messages with total file size in a box
print_in_box("\033[1mData has been modified and overwritten in\033[0m \033[94m{}\033[0m\n\033[1mTotal file size:\033[0m \033[92m{}\033[0m".format(input_output_file, convert_size(file_size)))
