--SQLite version
--Select data that's gonna be used
SELECT location, date, total_cases, new_cases, total_deaths , population 
FROM CovidDeaths 
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/total_cases)*100 AS DeathPercentage
FROM CovidDeaths cd 
ORDER BY 1,2
--Shows the likelihood of dying if you contract covid in this country
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/total_cases)*100 AS DeathPercentage
FROM CovidDeaths cd 
WHERE location LIKE 'Brazil'
ORDER BY 1,2
--Looking at Total Cases vs Population- percentage of population that got Covid
SELECT location, date, population, total_cases, (CAST(total_cases AS FLOAT)/population)*100 AS PercentageInfectedPopulation
FROM CovidDeaths cd 
WHERE location LIKE 'Brazil'
AND continent IS NOT NULL
ORDER BY 1,2
--Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((CAST(total_cases AS FLOAT)/population))*100 AS HighestPercentageInfectedPopulation
FROM CovidDeaths cd 
GROUP BY location, population 
ORDER BY HighestPercentageInfectedPopulation DESC
--Looking at countries with highest infection rate compared to the population by date

SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((CAST(total_cases AS FLOAT)/population))*100 AS HighestPercentageInfectedPopulation
FROM CovidDeaths cd 
GROUP BY location, population, date
ORDER BY HighestPercentageInfectedPopulation DESC
--Continents with the highest Death Count per Population
SELECT continent , MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths cd
WHERE continent IS NOT NULL 
GROUP BY continent  
ORDER BY TotalDeathCount DESC
--Countries with the highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths cd
WHERE continent IS NOT NULL 
GROUP BY location  
ORDER BY TotalDeathCount DESC
--Global numbers
SELECT SUM(new_cases) AS TotalNewCases, SUM((CAST(new_deaths AS INT))) AS TotalNewDeath, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths cd 
WHERE continent IS NOT NULL
ORDER BY 1,2
--Join both tables 
SELECT *
FROM CovidDeaths cd
JOIN CovidVaccination cv 
ON cd.location = cv.location 
AND cd.date = cv.date
--Total Population vs Vaccinations
SELECT cd.continent, cd.location , cd.date, cd.population, cv.new_vaccinations
,SUM(CAST(cv.new_vaccinations AS INT)) OVER (PARTITION BY cv.location ORDER BY cv.location, cv.date) AS RollingPeopleVaccinated
FROM CovidDeaths cd
JOIN CovidVaccination cv
ON cd.location = cv.location 
AND cd.date = cv.date
WHERE cd.location IS NOT NULL 
ORDER BY 2,3

	--cte
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT cd.continent, cd.location , cd.date, cd.population, cv.new_vaccinations
,SUM(CAST(cv.new_vaccinations AS INT)) OVER (PARTITION BY cv.location ORDER BY cv.location, cv.date) AS RollingPeopleVaccinated
FROM CovidDeaths cd
JOIN CovidVaccination cv
ON cd.location = cv.location 
AND cd.date = cv.date
WHERE cd.location IS NOT NULL 
)
SELECT *, (CAST(RollingPeopleVaccinated AS FLOAT)/population)*100 PercentPopulationVaccinated
FROM PopVsVac

--TempTable
DROP TABLE IF EXISTS PercentOfPopulationVaccinated;
CREATE TEMP TABLE PercentOfPopulationVaccinated
(
continent nvarchar(255), 
location nvarchar(255), 
date datetime, 
population numeric, 
new_vaccinations numeric, 
RollingPeopleVaccinated numeric
);

INSERT INTO PercentOfPopulationVaccinated
SELECT cd.continent, cd.location , cd.date, cd.population, cv.new_vaccinations
,SUM(CAST(cv.new_vaccinations AS INT)) OVER (PARTITION BY cv.location ORDER BY cv.location, cv.date) AS RollingPeopleVaccinated
FROM CovidDeaths cd
JOIN CovidVaccination cv
ON cd.location = cv.location 
AND cd.date = cv.date
WHERE cd.location IS NOT NULL;

SELECT *, (CAST(RollingPeopleVaccinated AS FLOAT)/population)*100 PercentPopulationVaccinated
FROM PercentOfPopulationVaccinated

--Creating view to store data for later visualizations
CREATE VIEW PercentOfPopulationVaccinated AS
SELECT cd.continent, cd.location , cd.date, cd.population, cv.new_vaccinations
,SUM(CAST(cv.new_vaccinations AS INT)) OVER (PARTITION BY cv.location ORDER BY cv.location, cv.date) AS RollingPeopleVaccinated
FROM CovidDeaths cd
JOIN CovidVaccination cv
ON cd.location = cv.location 
AND cd.date = cv.date
WHERE cd.location IS NOT NULL

SELECT *
FROM PercentOfPopulationVaccinated popv 
