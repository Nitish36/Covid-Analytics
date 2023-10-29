USE CovidDB;
-- Display Covid Death Data
SELECT * FROM dbo.CovidDeaths$;

-- Display Covid Vaccine Data
SELECT * FROM dbo.CovidVaccine$
WHERE continent is not null;

-- Calculate the percentage of people who got infected in your country

Select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as Death_Percentage
FROM dbo.CovidDeaths$
WHERE total_cases <> 0 and location = 'India' and continent is not null
ORDER BY Death_Percentage DESC;

-- Percentage of population who got covid
Select location,date,total_cases,population,(total_cases/population)*100 as Cases_Percentage
FROM dbo.CovidDeaths$
-- WHERE location like 'India'
ORDER BY location,date;

-- Highest infection rate compared to population
Select location,population,MAX(total_cases) as HighestInfectionCount,MAX(total_cases/population)*100 as Max_Infection_Percentage
FROM dbo.CovidDeaths$
WHERE continent is not null
GROUP BY location, population
ORDER BY Max_Infection_Percentage DESC;

-- Highest Death rate and highest death count
Select location,population,MAX(CAST(total_deaths as int)) as HighestDeathCount
FROM dbo.CovidDeaths$
WHERE continent is not null
GROUP BY location, population
ORDER BY HighestDeathCount DESC;

-- Showing the continents with the highest death count
Select continent,MAX(CAST(total_deaths as int)) as HighestDeathCount
FROM dbo.CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY HighestDeathCount DESC;

-- Global Numbers

Select date,SUM(new_cases) as Sum_of_new_cases,
SUM(CAST(new_deaths as int)) as Sum_of_new_deaths,
SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as Death_Percentage
FROM dbo.CovidDeaths$
WHERE new_cases <> 0 and continent is not null
GROUP BY date
ORDER BY 1;

Select SUM(new_cases) as total_cases,
SUM(CAST(new_deaths as int)) as Sum_of_new_deaths,
SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as Death_Percentage
FROM dbo.CovidDeaths$
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2;

-- Looking at total population vs vaccinations
WITH popvsvac (Continent,Location,Date,Population,New_Vaccinations,rolling_people_vaccinated) AS (
SELECT dea.continent,dea.location,dea.date,dea.population,dcv.new_vaccinations,
SUM(CAST(dcv.new_vaccinations as bigint)) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) as rolling_people_vaccinated
FROM dbo.CovidDeaths$ dea
JOIN dbo.CovidVaccine$ dcv
ON dea.location = dcv.location
AND dea.date = dcv.date
WHERE dea.continent is not null
--ORDER BY 2,1
)

SELECT *,(rolling_people_vaccinated/Population)*100 as percentage_of_vaccinated
FROM popvsvac;

-- Temp Table
DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(
	Continent Varchar(255),
	Location Varchar(255),
	Date datetime,
	Population numeric,
	New_Vaccinations numeric,
	rolling_people_vaccinated numeric
)

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent,dea.location,dea.date,dea.population,dcv.new_vaccinations,
SUM(CAST(dcv.new_vaccinations as bigint)) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) as rolling_people_vaccinated
FROM dbo.CovidDeaths$ dea
JOIN dbo.CovidVaccine$ dcv
ON dea.location = dcv.location
AND dea.date = dcv.date
WHERE dea.continent is not null
--ORDER BY 2,1

SELECT *,(rolling_people_vaccinated/Population)*100 as percentage_of_vaccinated
FROM PercentPopulationVaccinated;


-------------------------------  View Creation  -------------------------

-- CReation of view for later visualizations

CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent,dea.location,dea.date,dea.population,dcv.new_vaccinations,
SUM(CAST(dcv.new_vaccinations as bigint)) OVER(PARTITION BY dea.location ORDER BY dea.location,dea.date) as rolling_people_vaccinated
FROM dbo.CovidDeaths$ dea
JOIN dbo.CovidVaccine$ dcv
ON dea.location = dcv.location
AND dea.date = dcv.date
WHERE dea.continent is not null
--ORDER BY 2,1

SELECT * FROM PercentagePopulationVaccinated;

-- View to find percentage of total cases across years and months
CREATE VIEW PercentageofTotalCases AS
SELECT YEAR(date) as year,MONTH(date) as month,(SUM(new_cases)/SUM(total_cases))*100 as percentage_of_cases
FROM dbo.CovidDeaths$
GROUP BY YEAR(date),MONTH(date)

SELECT year as year,month as month, percentage_of_cases 
FROM PercentageofTotalCases
ORDER BY year,month;

-- View to find out how many people were fully vaccinated
CREATE VIEW CountOfPeopleFullyVaccinated AS
SELECT YEAR(date) as year,MONTH(date) as month,COUNT(people_fully_vaccinated) as countofvaccinated
FROM dbo.CovidVaccine$
GROUP BY YEAR(date),MONTH(date)

SELECT year,month,countofvaccinated
FROM CountOfPeopleFullyVaccinated
ORDER BY year,month;

-- Average deaths vs total cases across locations
CREATE VIEW CaseVsDeath AS
SELECT cv.location,SUM(cd.new_cases)/SUM(cd.total_cases)*100 AS case_percentage,SUM(cd.new_deaths)/SUM(cd.total_deaths)*100 as death_percentage
FROM dbo.CovidDeaths$ cd
INNER JOIN dbo.CovidVaccine$ cv
ON cd.location = cv.location
WHERE cd.total_cases <> 0 and cd.total_deaths <> 0
GROUP BY cv.location;

SELECT *
FROM CaseVsDeath
ORDER BY location;

-- Average deaths vs total_vaccinations throughout the year and month
CREATE VIEW DeathVsVaccinations AS
SELECT Year(cv.date) as year,MONTH(cv.date) as month,
SUM(cd.new_deaths)/SUM(cd.total_deaths)*100 AS death_percentage,
SUM(cv.new_vaccinations)/SUM(cv.total_vaccinations)*100 as vaccination_percentage
FROM dbo.CovidDeaths$ cd
INNER JOIN dbo.CovidVaccine$ cv
ON cd.location = cv.location
WHERE cv.total_vaccinations <> 0 and cd.total_deaths <> 0
GROUP BY Year(cv.date),MONTH(cv.date);

SELECT * FROM DeathVsVaccinations
ORDER BY year,month;


-- Yearly and monthly wise positive rate
CREATE VIEW Positive AS
SELECT Year(date) as year,MONTH(date) as month,AVG(positive_rate)*100 as mean_positive_rate
FROM dbo.CovidVaccine$
GROUP BY YEAR(date),MONTH(date);

SELECT *
FROM Positive
ORDER BY year,month;

