SELECT *
FROM PortfolioProject..CovidDeaths$
order by 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations$
--order by 3,4

--data is up until 30-04-2021

--..select the data that we are going to be using 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
order by 1,2

--looking at the total cases vs total deaths
--this shows the likelihood of dying if you contract COVID in a given country 
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location like '%Zealand%'
order by 1,2

--looking at total cases vs population 
--shows what percentage of population contracted COVID in New Zealand
SELECT location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
WHERE location like '%Zealand%'
order by 1,2

--Here we will be looking at countries with the highest infection rate compared to the population 
SELECT location, population, MAX(total_cases) as HighestInfectionCount,MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths$
GROUP BY population, location
order by PercentPopulationInfected desc

--Here we will look at how many people died from COVID, by country with the highest death count per population
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null 
GROUP BY location
order by TotalDeathCount desc
--we had the wrong data type which gave inpropper ordering, must be cast as int. 
--we found locations that should not be included such as continents so we must use WHERE function 

--breaking down by continent 
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null 
GROUP BY continent
order by TotalDeathCount desc

--global numbers 
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM
(new_Cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent is not null 
GROUP BY date
order by 1,2

--looking at covid vaccination data 
SELECT *
FROM PortfolioProject..CovidVaccinations$

--looking at total pop vs vaccinations 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ Dea
JOIN PortfolioProject..CovidVaccinations$ Vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
order by 2,3

--lets join the two tables together 
SELECT *
FROM PortfolioProject..CovidDeaths$ Dea
JOIN PortfolioProject..CovidVaccinations$ Vac
ON dea.location = vac.location
and dea.date = vac.date

--Use CTE 
WITH PopvsVac (Continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ Dea
JOIN PortfolioProject..CovidVaccinations$ Vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
--order by 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM popvsVac
--this gives the vaccination rate of each country 

--temp table 
Drop Table if exists #percentpopulationVaccinated
create table #percentpopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric, 
New_Vaccinations numeric, 
RollingPeopleVaccinated numeric
)

INSERT INTO #percentpopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ Dea
JOIN PortfolioProject..CovidVaccinations$ Vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
order by 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #percentpopulationVaccinated


--creating view to store data for visualisations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ Dea
JOIN PortfolioProject..CovidVaccinations$ Vac
ON dea.location = vac.location
and dea.date = vac.date
WHERE dea.continent is not null
--order by 2,3