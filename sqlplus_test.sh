# Read configuration variables from config file
source config.txt  # Assuming config.txt contains the connection details

# Connect to the remote Oracle database using SQL*Plus
echo "Connecting to the remote Oracle database..."
sqlplus -S $username/$password@$hostname:$port/$service_name <<EOF

-- Execute the SQL query and spool the output to a CSV file
SET PAGESIZE 0
SET FEEDBACK OFF
SET HEADING OFF
SET MARKUP CSV ON
SPOOL assets_temp.csv
SELECT 'MANUFACTURER_NM', 'MODEL_DS', 'SERIAL_NR', 'OFFICIAL_NAME', 'ASSET_TAG_NR', 'ACQUISITION_DT', 'CUSTODIAN_EMPLOYEE_ID', 'PROJECT_ID', 'ACTIVITY_ID', 'PO_ID', 'BLDG_RM_NR'
FROM DUAL;
SELECT /*+ HEADER */ MANUFACTURER_NM, MODEL_DS, SERIAL_NR, OFFICIAL_NAME, ASSET_TAG_NR, ACQUISITION_DT, CUSTODIAN_EMPLOYEE_ID, PROJECT_ID, ACTIVITY_ID, PO_ID, BLDG_RM_NR
FROM EDW_SHARE.AM_ASSET_EXTRACT
WHERE ASSET_STATUS_CD = 'I' AND BLDG_RM_NR LIKE '978%';
SPOOL OFF
EXIT
EOF

# Run python script to modify columns
python3 modify_csv.py
