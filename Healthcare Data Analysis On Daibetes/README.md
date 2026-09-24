### LOADING.

- The number_emergency was in bit. I changed it to int.
- When loading the IDS; the first column was in tinyin. I Changed it to just int.
- I had to split the ids mapping csv into 3 csv. This is to allow me bulk insert.


### Problems with tables contraints not taling nulls.
UPDATE changes the actual data values sitting inside existing rows. This is separate from ALTER TABLE — once the structural rule allows NULLs (after your ALTER TABLE), the UPDATE statement is the one that goes row by row and actually performs the data cleanup: converting the placeholder text '?' into a genuine NULL.

### Cleaing the ids_mapping tables.
The weight table has over 95% of missing null value, hence I will drop it.


### What INNER JOIN does here
sql
FROM diabetic_data_raw t
INNER JOIN (
    SELECT patient_nbr, MIN(encounter_id) AS first_encounter
    FROM diabetic_data_raw
    GROUP BY patient_nbr
) AS first_encounters 
ON t.patient_nbr = first_encounters.patient_nbr 
AND t.encounter_id = first_encounters.first_encounter

INNER JOIN only keeps rows where a match exists on both sides. It discards anything that doesn't have a matching counterpart.

Why that's exactly right in this case

Think about where the subquery (first_encounters) actually comes from — it's built entirely from diabetic_data_raw itself:

sql
SELECT patient_nbr, MIN(encounter_id) AS first_encounter
FROM diabetic_data_raw
GROUP BY patient_nbr

Every single patient_nbr that appears in the subquery is guaranteed to already exist in the main table — because that's literally where it came from. There is no possible scenario where first_encounters contains a patient_nbr that diabetic_data_raw doesn't have, since it's derived directly from that same table.

So the two sides of this join are guaranteed to always match — every row from the subquery will always find its corresponding row back in t. There's no "orphan" data on either side to worry about.

Why LEFT JOIN wouldn't change anything here (but why you'd normally consider it)

LEFT JOIN matters when you want to keep all rows from the left table even if there's no match on the right — filling in NULL for the right side's columns where no match exists.

But in your query, since the subquery is 100% derived from the same table you're joining it against, there's no case where a "left" row could possibly lack a match. Using LEFT JOIN here would produce the exact same result as INNER JOIN — just potentially slightly less efficient, since the query optimizer sometimes has to work a bit harder to prove that no NULL-padding cases exist with a LEFT JOIN, whereas INNER JOIN tells it directly "only keep matches" — which is a stronger, clearer signal of intent.

When you WOULD need LEFT JOIN instead

You'd reach for LEFT JOIN when the two tables are genuinely independent datasets that might not fully overlap — for example:

sql
SELECT p.patient_nbr, a.appointment_date
FROM patients p
LEFT JOIN appointments a
ON p.patient_nbr = a.patient_nbr

Here, some patients might have zero appointments. If you used INNER JOIN, those patients would disappear from your results entirely (since there's no matching appointment row). LEFT JOIN keeps every patient regardless, showing NULL for appointment_date when there's no match — useful when you specifically want to know about the absence of a match too.

Bottom line for your query

INNER JOIN is the correct and intentional choice here because:

The subquery is guaranteed to be a subset of the same table you're joining back into — no possibility of unmatched rows
INNER JOIN communicates your actual intent clearly: "only keep rows that are confirmed to be someone's first encounter"
It's typically the more efficient choice when you know matches are guaranteed, since the optimizer doesn't need to account for the "no match" case


