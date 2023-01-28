/*
Covid 19 Data Exploration

Skills used; Joins, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Select data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM CovidData.dbo.CovidDeaths$
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in the United States

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidData.dbo.CovidDeaths$
WHERE [location] = 'United States'
ORDER BY 1,2

--################################################################################
-- Total Cases vs Population
-- Shows what percentage of Population infected with Covid

SELECT Location, date, population, total_cases, (total_cases/population)*100 as Percent_Population_Infected
FROM CovidData.dbo.CovidDeaths$
ORDER BY 1,2

--################################################################################
-- Shows countries with highest infection rate compared to Population

SELECT Location, population, Max(total_cases) AS Hightest_Infection_Count, (MAX(total_cases)/population)*100 as Percent_Population_Infected
FROM CovidData.dbo.CovidDeaths$
GROUP BY Location, population
ORDER BY Percent_Population_Infected DESC

--################################################################################
-- Shows countries with hightest death count by population

SELECT [location], MAX(CAST(Total_deaths AS int)) AS Total_Death_Count
FROM CovidData.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY [location]
ORDER BY Total_Death_Count DESC

-- ###############################################################################
--LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population

SELECT continent, MAX(CAST(Total_deaths AS int)) AS Total_Death_Count
FROM CovidData.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY Total_Death_Count DESC

--################################################################################
-- Global Numbers  
-- Grouped by Date 

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS Death_Percentage
FROM CovidData.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY [date]
ORDER BY 1,2

--################################################################################
-- Not Grouped (one row)

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS Death_Percentage
FROM CovidData.dbo.CovidDeaths$
WHERE continent is not null
ORDER BY 1,2

--################################################################################
-- Looking at Total Population vs Vaccination 

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.[date]) AS rolling_people_vaccinated 
FROM CovidData.dbo.CovidDeaths$ Dea
JOIN CovidData.dbo.CovidVaccinations$ vac
ON dea.location = vac.[location]
and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--################################################################################
-- USE CTE 

WITH PopvsVac (continent, location, date, population, New_Vaccinations, rolling_people_vaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.[date]) AS rolling_people_vaccinated 
FROM CovidData.dbo.CovidDeaths$ Dea
JOIN CovidData.dbo.CovidVaccinations$ vac
ON dea.location = vac.[location]
and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (rolling_people_vaccinated/population)*100 AS rolling_percentage_vaccinated
FROM PopvsVac

--################################################################################
-- USE Temp Table 

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date datetime,
population numeric,
New_Vaccinations numeric,
rolling_people_vaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.[date]) AS rolling_people_vaccinated 
FROM CovidData.dbo.CovidDeaths$ Dea
JOIN CovidData.dbo.CovidVaccinations$ vac
ON dea.location = vac.[location]
and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (rolling_people_vaccinated/population)*100 AS rolling_percentage_vaccinated
FROM #PercentPopulationVaccinated

--################################################################################
--OR

-- bigint - for any integers larger than 2 billion
DROP TABLE IF EXISTS #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.[date]) AS rolling_people_vaccinated 
INTO #PercentPopulationVaccinated
FROM CovidData.dbo.CovidDeaths$ Dea
JOIN CovidData.dbo.CovidVaccinations$ vac
ON dea.location = vac.[location]
and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, ROUND((rolling_people_vaccinated/population)*100,2) AS rolling_percentage_vaccinated
FROM #PercentPopulationVaccinated

DROP TABLE #PercentPopulationVaccinated

--################################################################################
-- Creating View to store data for later visualization

DROP VIEW IF EXISTS PercentPopulationVaccinated;

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.[date]) AS rolling_people_vaccinated
FROM CovidData.dbo.CovidDeaths$ dea
JOIN CovidData.dbo.CovidVaccinations$ vac
ON dea.location = vac.[location]
and dea.date = vac.date
WHERE dea.continent is not null
