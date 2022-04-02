SELECT * FROM "Covid_deaths"
ORDER BY 3,4

;SELECT * FROM "Covid_vaccinations"
ORDER BY 3,4

;SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM "Covid_deaths"
WHERE continent is not null --To get rid of location being a continent
ORDER BY 1,2 

--Analyzing the Total Cases vs the Total Deaths
--Shows the percentage chance of death if diagnosed with COVID 19 in a specifc country
;SELECT location, date, total_cases, total_deaths,(total_deaths/total_cases) * 100 AS death_rate 
FROM "Covid_deaths"
WHERE location LIKE '%Canada%'
ORDER BY 1,2 

--Analyzing the Total Cases vs the population
--Shows the percentage of population to be diagnosed with COVID 19
;SELECT location, date, population, total_cases, (total_cases/population) * 100 AS percentpopulationinfected 
FROM "Covid_deaths"
WHERE location LIKE '%Canada%'
ORDER BY 1,2 

--Analyzing Countries with highest infection rate
--Used for sheet 4 in Tableau "COVID 19 statistics" (Percent Population Infected And Forecast)
;SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS percentpopulationinfected 
FROM "Covid_deaths"
WHERE continent is not null
GROUP BY location, population, date
ORDER BY percentpopulationinfected desc 

--Used for sheet 3 in Tableau "COVID 19 statistics" to create map (Percent Population Infected Per Country)
;SELECT location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS percentpopulationinfected 
FROM "Covid_deaths"
WHERE continent is not null
GROUP BY location, population, date
ORDER BY percentpopulationinfected desc

--Analyzing the countries with the highest death count per population
--Used for sheet 2 in Tableau "COVID 19 statistics" (Total Deaths Per Continent)
;SELECT location, MAX(total_deaths) AS TotalDeathCount
From "Covid_deaths"
WHERE continent is null -- Where continents is null, the location is a continent
and location not in ('World','Upper middle income', 'High income', 'Lower middle income',
					 'Low inocome', 'European Union', 'Low income', 'International')
GROUP BY location
ORDER BY TotalDeathCount desc 

-- Let's try breaking things up by continent
;SELECT continent, MAX(total_deaths) AS TotalDeathCount
From "Covid_deaths"
WHERE continent is not null
Group by continent
ORDER BY TotalDeathCount desc 

--Global numbers 
--Total number of deaths globally
;SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths,
SUM(new_deaths)/SUM(new_cases)* 100 AS GlobalDeathRate 
From "Covid_deaths"
WHERE continent is not null
GROUP BY date 
ORDER BY 1,2


-- Looking at Global Numbers
-- Used for Sheet 1 in Tableau "COVID 19 statistics" (Global Numbers)
;SELECT SUM(new_cases) as total_cases, SUM(new_deaths) AS total_deaths,
SUM(new_deaths)/SUM(new_cases)* 100 AS GlobalDeathRate 
FROM "Covid_deaths"
WHERE continent is not null
--Group by date 
ORDER BY 1,2

--Joining both tables together on date and location
--Analyzing the Total population VS the Total Vaccinations
;SELECT dea.continent, dea.location, dea.date, dea.population, new_vaccinations 
,SUM(new_vaccinations) OVER (partition by dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM "Covid_deaths" dea
JOIN "Covid_vaccinations" vac
	ON dea.location = vac.location
	and dea.date = vac.date 
WHERE dea.continent is not null
ORDER BY 2,3


-- USE A CTE to calculate the accumulation of % of people vaccinated as days pass. 

;With popVSvac(continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, new_vaccinations, 
SUM(new_vaccinations) OVER (partition by dea.location order by dea.location, dea.date) AS rollingpeoplevaccinated
FROM "Covid_deaths" dea
JOIN "Covid_vaccinations" vac
	ON dea.location = vac.location 
	and dea.date = vac.date 
WHERE dea.continent is not null
--order by 2,3
)
SELECT *, (rollingpeoplevaccinated/population) * 100 AS Vaccinations_vs_population from popVSvac


--Trying a Temp Table

;DROP TABLE if exists percentpopulationvaccinated 
;CREATE TABLE percentpopulationvaccinated 
(continent varchar(255),
 location varchar(255),
 date timestamp,
 population numeric, 
 new_vaccinations numeric, 
 rollingpeoplevaccinated numeric)

;Insert into percentpopulationvaccinated 
(SELECT dea.continent, dea.location, dea.date, dea.population, new_vaccinations, 
SUM(new_vaccinations) OVER (partition by dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM "Covid_deaths" dea
JOIN "Covid_vaccinations" vac
	ON dea.location = vac.location 
 	and dea.date = vac.date 
WHERE dea.continent is not null)
--order by 2,3

;SELECT *, (rollingpeoplevaccinated/population) * 100 AS Vaccinations_vs_population
from percentpopulationvaccinated 

--Creating a view to store data for later

;CREATE VIEW percentofpopulationvaccinated AS 
(SELECT dea.continent, dea.location, dea.date, dea.population, new_vaccinations, 
SUM(new_vaccinations) OVER (partition by dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM "Covid_deaths" dea
JOIN "Covid_vaccinations" vac
ON dea.location = vac.location and dea.date = vac.date 
WHERE dea.continent is not null)
--order by 2,3

