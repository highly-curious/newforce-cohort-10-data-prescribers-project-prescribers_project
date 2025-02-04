
-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
-- 1912011792 David Coffey
SELECT p.npi, pr.total_claim_count
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
ORDER BY total_claim_count DESC;

	
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT p.nppes_provider_first_name, p.nppes_provider_last_org_name, p.specialty_description, pr.total_claim_count
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
ORDER BY total_claim_count DESC;

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
-- Family Practice
SELECT p.specialty_description, pr.total_claim_count
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
GROUP BY p.specialty_description, pr.total_claim_count
ORDER BY total_claim_count DESC;

--     b. Which specialty had the most total number of claims for opioids?
-- Nurse Practicioner
SELECT p.specialty_description, 
    SUM(pr.total_claim_count) AS total_opioid_claims
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
JOIN drug d ON pr.drug_name = d.drug_name
WHERE d.opioid_drug_flag = 'Y'
GROUP BY p.specialty_description
ORDER BY total_opioid_claims DESC;

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT p.specialty_description, pr.total_claim_count
FROM prescriber p
LEFT JOIN prescription pr ON p.npi = pr.npi
WHERE pr.npi IS NULL
GROUP BY p.specialty_description, pr.total_claim_count;

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

SELECT p.specialty_description, 
  ROUND(100.0 * SUM(CASE WHEN d.opioid_drug_flag = 'Y' THEN pr.total_claim_count ELSE 0 END) / SUM(pr.total_claim_count), 2) AS opioid_claim_percentage
FROM prescriber p
JOIN prescription pr ON p.npi = pr.npi
JOIN drug d ON pr.drug_name = d.drug_name
GROUP BY p.specialty_description
ORDER BY opioid_claim_percentage DESC;

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
-- INSULIN GLARGINE,HUM.REC.ANLOG
SELECT d.generic_name, SUM(pr.total_drug_cost) AS total_drug_cost
FROM drug d
JOIN prescription pr ON d.drug_name = pr.drug_name
GROUP BY d.generic_name
ORDER BY total_drug_cost DESC
LIMIT 1;


--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
-- LEDIPASVIR/SOFOSBUVIR
SELECT d.generic_name, ROUND(SUM(pr.total_drug_cost / pr.total_30_day_fill_count), 2) AS total_drug_cost_per_day
FROM drug d
JOIN prescription pr ON d.drug_name = pr.drug_name
GROUP BY d.generic_name
ORDER BY total_drug_cost_per_day DESC
LIMIT 1;

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 
SELECT drug_name,
    CASE 
        WHEN opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type
FROM drug
ORDER BY drug_type;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
WITH categorized_drugs AS (
    SELECT 
        d.drug_name,
        CASE 
            WHEN opioid_drug_flag = 'Y' THEN 'opioid'
            WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
            ELSE 'neither'
        END AS drug_type
    FROM drug d
)
SELECT 
    cd.drug_type, 
    SUM(pr.total_drug_cost)::MONEY AS total_cost
FROM categorized_drugs cd
JOIN prescription pr ON cd.drug_name = pr.drug_name
GROUP BY cd.drug_type
ORDER BY cd.drug_type;


-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT (c.cbsa) AS cbsa_tn
FROM cbsa c
JOIN fips_county fc ON c.fipscounty = fc.fipscounty
WHERE fc.state = 'TN'

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT c.cbsaname AS cbsaname_tn, SUM(p.population) AS total_population
FROM cbsa c
JOIN fips_county fc ON c.fipscounty = fc.fipscounty
JOIN population p ON c.fipscounty = p.fipscounty
WHERE fc.state = 'TN'
GROUP BY cbsaname_tn
ORDER BY total_population DESC;

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
WITH county_data AS (
    SELECT fc.county AS county_name_non_cbsa, 
        p.population AS county_pop_non_cbsa
    FROM fips_county fc
    JOIN population p ON p.fipscounty = fc.fipscounty  
    LEFT JOIN cbsa c ON c.fipscounty = fc.fipscounty
    WHERE fc.state = 'TN'
    AND c.fipscounty IS NULL
    ORDER BY county_pop_non_cbsa DESC
    LIMIT 1)

SELECT county_name_non_cbsa, county_pop_non_cbsa AS max_population FROM county_data;


-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
WITH high_claim_drugs AS (
    SELECT drug_name, total_claim_count
    FROM prescription
    WHERE total_claim_count >= 3000
    ORDER BY total_claim_count DESC)
	
SELECT d.drug_name,
    CASE 
        WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type,
    hc.total_claim_count
FROM high_claim_drugs hc
JOIN drug d ON hc.drug_name = d.drug_name
ORDER BY drug_type;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
WITH high_claim_drugs AS (
    SELECT drug_name, total_claim_count
    FROM prescription p
    WHERE total_claim_count >= 3000
    ORDER BY total_claim_count DESC)

SELECT d.drug_name, h.total_claim_count,
    CASE 
        WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type,
    pr.nppes_provider_first_name,
    pr.nppes_provider_last_org_name
FROM high_claim_drugs h
JOIN drug d ON h.drug_name = d.drug_name
JOIN prescription p ON h.drug_name = p.drug_name 
JOIN prescriber pr ON pr.npi = p.npi
ORDER BY h.total_claim_count DESC;


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT p.npi, d.drug_name
FROM prescriber p
CROSS JOIN drug d 
WHERE p.specialty_description = 'Pain Management'
AND p.nppes_provider_city = 'NASHVILLE'
AND d.opioid_drug_flag = 'Y';


--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT p.npi,
    d.drug_name,
    COALESCE(SUM(pc.total_claim_count), 0) AS total_claim_count
FROM prescriber p
CROSS JOIN drug d
LEFT JOIN prescription pc ON p.npi = pc.npi AND d.drug_name = pc.drug_name
WHERE p.specialty_description = 'Pain Management'
    AND p.nppes_provider_city = 'NASHVILLE'
    AND d.opioid_drug_flag = 'Y'
GROUP BY p.npi, d.drug_name
ORDER BY total_claim_count DESC;
    
