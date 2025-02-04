-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT COUNT(*) AS providers__with_no_prescriptions
FROM prescriber p
WHERE NOT EXISTS (
    SELECT 1
    FROM prescription pc
    WHERE pc.npi = p.npi);

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT d.generic_name,
    COUNT(*) AS total_prescriptions
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
JOIN prescriber pr ON p.npi = pr.npi
WHERE pr.specialty_description = 'Family Practice'
GROUP BY d.generic_name
ORDER BY total_prescriptions DESC
LIMIT 5;

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT d.generic_name,
COUNT(*) AS total_prescriptions
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
JOIN prescriber pr ON p.npi = pr.npi
WHERE pr.specialty_description = 'Cardiology'
GROUP BY d.generic_name
ORDER BY total_prescriptions DESC
LIMIT 5;

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
SELECT d.generic_name,
    COUNT(*) AS total_prescriptions
FROM prescription p
JOIN drug d ON p.drug_name = d.drug_name
JOIN prescriber pr ON p.npi = pr.npi
WHERE pr.specialty_description IN ('Family Practice', 'Cardiology')
GROUP BY d.generic_name
ORDER BY total_prescriptions DESC
LIMIT 5;

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
--     b. Now, report the same for Memphis.
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

-- a. Nashville
SELECT p.nppes_provider_first_name, p. nppes_provider_last_org_name, p.npi,
    SUM(pr.total_claim_count) AS total_claims, p.nppes_provider_city AS city
FROM prescription pr
JOIN prescriber p ON pr.npi = p.npi
WHERE p.nppes_provider_city = 'NASHVILLE'
GROUP BY p.npi, p.nppes_provider_first_name, p. nppes_provider_last_org_name, p.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;


-- b. Memphis
SELECT p.nppes_provider_first_name, p. nppes_provider_last_org_name, p.npi,
    SUM(pr.total_claim_count) AS total_claims, p.nppes_provider_city AS city
FROM prescription pr
JOIN prescriber p ON pr.npi = p.npi
WHERE p.nppes_provider_city = 'MEMPHIS'
GROUP BY p.npi, p.nppes_provider_first_name, p. nppes_provider_last_org_name, p.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;


SELECT p.npi,
    SUM(pr.total_claim_count) AS total_claims, p.nppes_provider_city AS city
FROM prescription pr
JOIN prescriber p ON pr.npi = p.npi
WHERE p.nppes_provider_city = 'KNOXVILLE'
GROUP BY p.npi, p.nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

-- c. Knoxville and Chattanooga combined
SELECT p.nppes_provider_first_name, 
    p.nppes_provider_last_org_name, 
    p.npi,
    SUM(pr.total_claim_count) AS total_claims,
    CASE 
        WHEN p.nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA') THEN p.nppes_provider_city
        ELSE NULL
    END AS city
FROM prescription pr
JOIN prescriber p ON pr.npi = p.npi
WHERE p.nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')
GROUP BY 
    p.npi, 
    p.nppes_provider_first_name, 
    p.nppes_provider_last_org_name,
    CASE 
        WHEN p.nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA') THEN p.nppes_provider_city
        ELSE NULL
    END
ORDER BY total_claims DESC;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
SELECT fc.county, od.overdose_deaths AS od_grtr_than_avg
FROM overdose_deaths od
JOIN fips_county fc ON CAST(fc.fipscounty AS integer) = od.fipscounty
WHERE od.overdose_deaths > (SELECT AVG(overdose_deaths) FROM overdose_deaths)
ORDER BY od.overdose_deaths DESC;

-- 5.
--     a. Write a query that finds the total population of Tennessee.
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

    -- a. Total population of Tennessee
SELECT SUM(p.population) AS total_population_TN
FROM population p
JOIN fips_county fc ON fc.fipscounty = p.fipscounty
WHERE fc.state = 'TN';

-- b. Population and percentage for each county
WITH total_pop AS (
    SELECT SUM(p.population) AS total_population_TN
    FROM population p
    JOIN fips_county fc ON fc.fipscounty = p.fipscounty
    WHERE fc.state = 'TN')

SELECT fc.county, 
    p.population,
    ROUND((p.population * 100.0 / tp.total_population_TN), 2) AS population_percentage
FROM population p
JOIN fips_county fc ON fc.fipscounty = p.fipscounty
JOIN total_pop tp ON 1=1
WHERE fc.state = 'TN'
ORDER BY population_percentage DESC;

