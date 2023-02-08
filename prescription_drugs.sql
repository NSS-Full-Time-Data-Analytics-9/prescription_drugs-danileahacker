--1. 
--a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi,
	SUM(total_claim_count) AS total_drugs_claims
FROM prescription
WHERE total_claim_count IS NOT NULL
GROUP BY npi
ORDER BY total_drugs_claims DESC;
-- npi 1881634483 had the highest number of claims, with 99,707.

--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,
--specialty_description, and the total number of claims.
SELECT
	nppes_provider_first_name AS first_name,
	nppes_provider_last_org_name AS last_name,
	specialty_description,
	SUM(total_claim_count) AS total_drugs_claims
FROM prescription
	LEFT JOIN prescriber
	USING(npi)
WHERE total_claim_count IS NOT NULL
GROUP BY first_name, last_name, specialty_description
ORDER BY total_drugs_claims DESC;

--2. 
--a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT
	specialty_description,
	SUM(total_claim_count) AS total_drugs_claims
FROM prescription
	LEFT JOIN prescriber
	USING(npi)
WHERE total_claim_count IS NOT NULL
GROUP BY specialty_description
ORDER BY total_drugs_claims DESC;
--Family Practice had the highest number of claims at 9,752,347.

--b. Which specialty had the most total number of claims for opioids?
SELECT
	specialty_description,
	SUM(total_claim_count) AS total_drug_claims
FROM prescription
	LEFT JOIN prescriber
	USING(npi)
	LEFT JOIN drug --join for drug classification specifics.
	USING(drug_name)
WHERE (opioid_drug_flag = 'Y') --narrowed down search to only include opioids.
GROUP BY specialty_description
ORDER BY total_drug_claims DESC;
--Nurse Practitioner had the highest number of opioid-related claims at 900,845.

--c. **Challenge Question:** Are there any specialties that appear in the prescriber table
--that have no associated prescriptions in the prescription table?
SELECT
	specialty_description,
	COUNT(*) AS num_of_nulls_prescription
FROM prescriber
	LEFT JOIN prescription
	USING(npi)
WHERE prescription.npi IS NULL
GROUP BY specialty_description
ORDER BY num_of_nulls_prescription DESC;

SELECT*
FROM prescription;
--I know there's a hole somewhere... not sure how to close it. i.e. - Nurse Practitioner definitely had a lot of claims.

--d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!*
--For each specialty, report the percentage of total claims by that specialty which are for opioids.
--Which specialties have a high percentage of opioids?

--3. 
--a. Which drug (generic_name) had the highest total drug cost?
SELECT drug_name, SUM(total_drug_cost) AS total_cost
FROM prescription
GROUP BY drug_name
ORDER BY total_cost DESC
LIMIT 10;
--Lyrica was at the top of the list, at a total cost of $78,645,939.89.

--b. Which drug (generic_name) has the hightest total cost per day?
--**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT drug_name, total_drug_cost, (total_30_day_fill_count*30 + total_day_supply) AS total_fill_count_by_day
FROM prescription;

SELECT
	drug_name,
	--total_drug_cost,
	--(total_30_day_fill_count*30 + total_day_supply) AS total_fill_count_by_day,
	ROUND(SUM(((total_drug_cost)/NULLIF(total_30_day_fill_count*30 + total_day_supply, 0))), 2) AS cost_per_day
FROM prescription
GROUP BY drug_name
ORDER BY cost_per_day DESC;
--Harvoni appears to have the highest cost per day, at 42,613.53 per day.

--4.
--a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid'
--for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y',
--and says 'neither' for all other drugs.
--tables involved: drug
SELECT
	drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug

--b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics.
--Hint: Format the total costs as MONEY for easier comparision.
SELECT
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type,
	SUM(total_drug_cost) AS total_cost
FROM drug
	INNER JOIN prescription
	USING(drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC;

--5. 
--a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(*) AS count_of_cbsa_tn
FROM cbsa
WHERE cbsaname ILIKE '%TN' OR cbsaname ILIKE '%TN-%';
--there are 56 CBSAs in TN.

--b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT DISTINCT(cbsaname), SUM(population) AS total_population
FROM cbsa
	LEFT JOIN population
	USING(fipscounty)
WHERE population IS NOT NULL
GROUP BY cbsaname
ORDER BY total_population DESC;
--Nashville-Davidson-Murfreesboro-Franklin, TN has the largest population of the CBSAs, with 1,830,410.
--Morristown, TN has the smallest population, with 116,352.

--c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT county, SUM(population) AS total_pop
FROM fips_county
	RIGHT JOIN population
	USING(fipscounty)
	LEFT JOIN cbsa
	USING(fipscounty)
WHERE cbsa.fipscounty IS NULL
GROUP BY county
ORDER BY total_pop DESC;
--not sure if this is the correct way to find counties not in a CBSA...
--Sevier county has the largest population out of counties not in a CBSA, at 95,523.

--6. 
--a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count > 3000;

--b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'other' END AS drug_type
FROM prescription
	LEFT JOIN drug
	USING(drug_name)
WHERE total_claim_count > 3000;

--c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT drug_name, total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'other' END AS drug_type,
	nppes_provider_first_name AS first_name,
	nppes_provider_last_org_name AS last_name
FROM prescription
	LEFT JOIN drug
	USING(drug_name)
	LEFT JOIN prescriber
	USING(npi)
WHERE total_claim_count > 3000;

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims
--they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment')
--in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y').
--**Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
--tables: drug, prescriber
SELECT*
FROM drug
	CROSS JOIN prescriber
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';

--b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations,
--whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
WITH drug_per_prescriber AS (SELECT*
							FROM drug
								CROSS JOIN prescriber
							WHERE specialty_description = 'Pain Management'
								AND nppes_provider_city = 'NASHVILLE'
								AND opioid_drug_flag = 'Y')
SELECT drug_per_prescriber.npi,
		drug_per_prescriber.drug_name,
		SUM(total_claim_count) AS claim_count
FROM prescription
	INNER JOIN drug_per_prescriber
	ON prescription.npi = drug_per_prescriber.npi
GROUP BY drug_per_prescriber.npi, drug_per_prescriber.drug_name;


--c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0.
--Hint - Google the COALESCE function.
WITH drug_per_prescriber AS (SELECT*
							FROM drug
								CROSS JOIN prescriber
							WHERE specialty_description = 'Pain Management'
								AND nppes_provider_city = 'NASHVILLE'
								AND opioid_drug_flag = 'Y')
SELECT COALESCE(drug_per_prescriber.npi),
		COALESCE(drug_per_prescriber.drug_name),
		COALESCE(SUM(total_claim_count)) AS claim_count
FROM prescription
	INNER JOIN drug_per_prescriber
	ON prescription.npi = drug_per_prescriber.npi
GROUP BY drug_per_prescriber.npi, drug_per_prescriber.drug_name;
--it doesn't appear that it changed anything...
