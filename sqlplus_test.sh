#!/bin/bash

# Check if config file exists
if [ ! -f "config.txt" ]; then
    echo "Configuration file 'config.txt' not found. Please enter the details
manually"

    # Prompt user for connection details
    read -p "Enter username: " username
    read -s -p "Enter password: " password
    echo
    read -p "Enter hostname: " hostname
    read -p "Enter port: " port
    read -p "Enter service name: " service_name
else
    # Read configuration variables from config file
    source config.txt  
fi

# Connect to the remote Oracle database using SQL*Plus
echo "Connecting to the remote Oracle database..."
sqlplus -S $username/$password@$hostname:$port/$service_name <<EOF>/dev/null

-- Set SQL*Plus settings
SET sqlformat csv

SPOOL assets_test.csv
SELECT MANUFACTURER_NM, MODEL_DS, SERIAL_NR, OFFICIAL_NAME, ASSET_TAG_NR, ACQUISITION_DT, CUSTODIAN_EMPLOYEE_ID, PROJECT_ID, ACTIVITY_ID, PO_ID, BLDG_RM_NR
FROM EDW_SHARE.AM_ASSET_EXTRACT
WHERE ASSET_STATUS_CD = 'I' AND BLDG_RM_NR LIKE '978%';
SPOOL OFF

EOF

# Python script to modify CSV data
python3 << PYSCRIPT

import csv
import re
from datetime import date
import time

# Generate the current date in YYYY-MM-DD format
current_date = date.today()

# Input CSV file containing the data
input_file = 'assets_test.csv'

# Output CSV file
output_file = f'assets_test_output_{current_date}.csv'

# Function to modify rows and add new columns
def modify_rows(rows):
    modified_rows = []
    for row in rows:
        if 'BLDG_RM_NR' in row:
            bldg_rm_nr = row['BLDG_RM_NR']
            if bldg_rm_nr is None:
                # Handle the case when the value in 'BLDG_RM_NR' column is None
                continue

            bldg = '978' if '978' in bldg_rm_nr else ''
            rm = re.sub(r'[^0-9]', '', bldg_rm_nr[4:])
            space = re.search(r'[A-Za-z]', bldg_rm_nr)
            space = space.group(0) if space else ''
            floor = ''
            for char in bldg_rm_nr:
                if char.isdigit() and char in ['3', '4']:
                    floor = char
                    break
            modified_row = {
                'MANUFACTURER_NM': row['MANUFACTURER_NM'],
                'MODEL_DS': row['MODEL_DS'],
                'SERIAL_NR': row['SERIAL_NR'],
                'OFFICIAL_NAME': row['OFFICIAL_NAME'],
                'ASSET_TAG_NR': row['ASSET_TAG_NR'],
                'ACQUISITION_DT': row['ACQUISITION_DT'],
                'CUSTODIAN_EMPLOYEE_ID': row['CUSTODIAN_EMPLOYEE_ID'],
                'PROJECT_ID': row['PROJECT_ID'],
                'ACTIVITY_ID': row['ACTIVITY_ID'],
                'PO_ID': row['PO_ID'],
                'BLDG': bldg.strip(),
                'RM': rm.strip(),
                'SPACE': space.strip(),
                'FLOOR': floor.strip(),
                'ASSIGNED_USER': ''  # Empty for now, can be filled later
            }
            modified_rows.append(modified_row)
            # Simulate delay for demonstration
            time.sleep(0.1)  # Delay for 0.1 second
    return modified_rows

# Read the input CSV file
with open(input_file, 'r', newline='') as infile:
    reader = csv.DictReader(infile)
    # Modify the rows
    modified_rows = modify_rows(reader)

# Output column names
output_col_names = ['MANUFACTURER_NM', 'MODEL_DS', 'SERIAL_NR', 'OFFICIAL_NAME', 'ASSET_TAG_NR', 'ACQUISITION_DT',
                    'CUSTODIAN_EMPLOYEE_ID', 'PROJECT_ID', 'ACTIVITY_ID', 'PO_ID', 'BLDG', 'RM', 'SPACE', 'FLOOR',
                    'ASSIGNED_USER']

# Write the modified data to the output CSV file
with open(output_file, 'w', newline='') as outfile:
    writer = csv.DictWriter(outfile, fieldnames=output_col_names)
    writer.writeheader()  # Write the column names as the header
    writer.writerows(modified_rows)  # Write the modified data rows

print(f"Data exported to {output_file} successfully.")
