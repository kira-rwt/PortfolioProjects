SELECT *
FROM PortfolioProject..covidDeath
WHERE continent IS NOT NULL
ORDER BY 3,4

/* select *
 from PortfolioProject..covidVaccination
 order by 3,4 */
 
 -- select data that we are going to be using

 SELECT Location, Date, total_cases, new_cases, total_deaths, population
 FROM PortfolioProject..covidDeath
 ORDER BY 1,2

 -- total cases and total deaths
 -- shows likelihood of dying if you contract covid in your country
 SELECT Location, Date, total_cases, total_deaths,
 (CONVERT(float, total_deaths) / CONVERT(float, total_cases))*100 AS DeathPercentage
 FROM PortfolioProject..covidDeath
 WHERE location LIKE '%India%'
 ORDER BY 1,2

 --Looking at total cases vs population
 -- shows what percentage of population got covid

  SELECT Location, Date, total_cases, population,
 (CONVERT(float, total_cases) / CONVERT(float, population))*100 AS CovidCasesPercentage
 FROM PortfolioProject..covidDeath
 WHERE location LIKE '%India%'
 ORDER BY 1,2

 --Looking at Countries with Highest Infection Rate Compared to Population
  SELECT Location, population, MAX(total_cases) AS HighestInfectionRate,
 MAX((total_cases/population))*100 AS PercentPopulationInfected
 FROM PortfolioProject..covidDeath
 GROUP BY Location, population
 ORDER BY PercentPopulationInfected DESC

 --Showing Countries highest death count per population

 SELECT Location, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
 FROM PortfolioProject..covidDeath
 WHERE continent IS NOT NULL
 GROUP BY Location
 ORDER BY TotalDeathCount DESC

 -- Breaking things down by continent

  SELECT continent, SUM(CAST(total_deaths as INT)) AS TotalDeathCount
 FROM PortfolioProject..covidDeath
 WHERE continent IS NOT NULL
 GROUP BY continent
 ORDER BY TotalDeathCount DESC

 -- Showing continent highest death rate count per population

 SELECT continent, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
 FROM PortfolioProject..covidDeath
 WHERE continent IS NOT NULL
 GROUP BY continent
 ORDER BY TotalDeathCount DESC

 --Global Numbers
 SELECT Date, SUM(new_cases) AS TotalCases, SUM(CAST(total_deaths AS INT)) AS TotalDeath, 
 (SUM(CAST(total_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
 FROM PortfolioProject..covidDeath
 WHERE continent IS NOT NULL
 GROUP BY date
 ORDER BY 1,2

 SELECT SUM(new_cases) AS TotalCases, SUM(CAST(total_deaths AS INT)) AS TotalDeath, 
 (SUM(CAST(total_deaths AS INT))/SUM(new_cases))*100 AS DeathPercentage
 FROM PortfolioProject..covidDeath
 WHERE continent IS NOT NULL
 ORDER BY 1,2

 /* NOW I AM USING VACCINATION DATABASE */

 SELECT *
 FROM PortfolioProject..covidVaccination

 -- Join death and vaccination DB on the bases of location and date

 SELECT *
 FROM PortfolioProject..covidVaccination Vac
 JOIN PortfolioProject..covidDeath Dea
 ON Dea.location = Vac.location AND Dea.date = Vac.date

 --Looking total population vs total vaccination

 SELECT Dea.continent, Dea.location, Dea.date, population, Vac.new_vaccinations, 
 SUM(CONVERT (INT, Vac.new_vaccinations)) OVER (PARTITION BY Dea.Location ORDER BY Dea.Location, Dea.Date) AS RollingPeopleVaccinated
 FROM PortfolioProject..covidDeath Dea
 JOIN PortfolioProject..covidVaccination Vac
 ON Dea.location = Vac.location AND Dea.date = Vac.date
 WHERE Dea.continent IS NOT NULL
 ORDER BY 2,3

 --Using CTE

 With PopVsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
 AS
 (
 SELECT Dea.continent, Dea.location, Dea.date, population, Vac.new_vaccinations, 
 SUM(CONVERT (INT, Vac.new_vaccinations)) OVER (PARTITION BY Dea.Location ORDER BY Dea.Location, Dea.Date) AS RollingPeopleVaccinated
 
 FROM PortfolioProject..covidDeath Dea
 JOIN PortfolioProject..covidVaccination Vac
 ON Dea.location = Vac.location AND Dea.date = Vac.date
 WHERE Dea.continent IS NOT NULL
 )
 SELECT *, (RollingPeopleVaccinated/Population)*100
 FROM PopVsVac

 --TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    Dea.continent,
    Dea.location,
    Dea.date,
    Dea.population,
    Vac.new_vaccinations,
    --SUM(CONVERT(INT, Vac.new_vaccinations)) OVER (PARTITION BY Dea.Location ORDER BY Dea.Location, Dea.Date) AS RollingPeopleVaccinated
	SUM(CONVERT(NUMERIC, Vac.new_vaccinations)) OVER (PARTITION BY Dea.Location ORDER BY Dea.Location, Dea.Date) AS RollingPeopleVaccinated
FROM
    PortfolioProject..covidDeath Dea
JOIN PortfolioProject..covidVaccination Vac ON Dea.location = Vac.location AND Dea.date = Vac.date;

-- Use a larger numeric data type for the calculation
SELECT * , (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated;


-- Creating View to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS 
SELECT
    Dea.continent,
    Dea.location,
    Dea.date,
    Dea.population,
    Vac.new_vaccinations,
    --SUM(CONVERT(INT, Vac.new_vaccinations)) OVER (PARTITION BY Dea.Location ORDER BY Dea.Location, Dea.Date) AS RollingPeopleVaccinated
	SUM(CONVERT(NUMERIC, Vac.new_vaccinations)) OVER (PARTITION BY Dea.Location ORDER BY Dea.Location, Dea.Date) AS RollingPeopleVaccinated
FROM
    PortfolioProject..covidDeath Dea
JOIN PortfolioProject..covidVaccination Vac ON Dea.location = Vac.location AND Dea.date = Vac.date
WHERE Dea.continent IS NOT NULL

SELECT * 
FROM PercentPopulationVaccinated
