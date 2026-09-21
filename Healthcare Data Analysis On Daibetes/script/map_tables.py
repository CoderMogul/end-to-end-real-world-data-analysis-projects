# --- Import the necessary libraries ---
from pathlib import Path
import pandas as pd
import pyodbc

# --- Config: map header name -> table name ---
section_table_map = {
    "admission_type_id": "admission_type",
    "discharge_disposition_id": "discharge_disposition",
    "admission_source_id": "admission_source"
}

id_column_map = {table: id_col for id_col, table in section_table_map.items()}

# --- define the path dir of the dataset ---
base_dir = Path(__file__).resolve().parents[1]
file_name = "IDS_mapping_raw.csv"
file_path = base_dir / "data" / "raw" / file_name

# --- Database connection ---
conn = pyodbc.connect(
    "Driver={SQL Server};"
    "Server=DESKTOP-DKLV564\\SQLEXPRESS;"
    "Database=hospital_readmissions;"
    "Trusted_Connection=yes;"
)
cursor = conn.cursor()

# --- Read raw lines from the CSV file ---
with open(file_path, "r", encoding="utf-8-sig") as f:
    lines = [line.rstrip("\n").rstrip("\r") for line in f]

# --- Parse into sections based on the header lines ---
sections = {}
current_table = None

for line in lines:
    stripped_line = line.strip().strip(",")
    if stripped_line == "":
        current_table = None
        continue

    first_col = line.split(',', 1)[0].strip()

    if first_col in section_table_map:
        current_table = section_table_map[first_col]
        sections[current_table] = []
        continue

    if current_table is not None:
        row = line.split(',', 1)
        if row[0].strip() == "":
            continue
        sections[current_table].append(row)

# --- Convert each section into a DataFrame ---
dataframes = {}
for table_name, rows in sections.items():
    df = pd.DataFrame(rows, columns=["id", "description"])
    df["id"] = df["id"].astype(int)
    df["description"] = df["description"].str.strip()
    dataframes[table_name] = df

# --- Insert each DataFrame into the corresponding database table ---
for table_name, df in dataframes.items():
    id_col = id_column_map[table_name]
    for _, row in df.iterrows():
        description_value = row["description"]
        if pd.isna(description_value):
            description_value = None

        cursor.execute(f"""
        INSERT INTO {table_name} ({id_col}, description)
        VALUES (?, ?)
        """,
        int(row["id"]), description_value
        )
    conn.commit()
    print(f"{table_name} inserted successfully ({len(df)} rows).")