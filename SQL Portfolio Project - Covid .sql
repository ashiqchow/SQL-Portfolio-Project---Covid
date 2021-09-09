Select *
from PortfolioCaseOne..CovidDeaths$
order by 3,4

--select *
--from PortfolioCaseOne..CovidVaccinations$
--order by 3,4

-- select the data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioCaseOne..CovidDeaths$
order by 1,2


-- Looking at the total cases vs total deaths
-- Shows the likelihood hos dying if you contract covid in your country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercantage
from PortfolioCaseOne..CovidDeaths$
where location = 'Sweden'
order by 1,2

-- Looking at the total cases vs population
-- Shows what percentage of the population contracted covid in your country

Select location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfectioned
from PortfolioCaseOne..CovidDeaths$
where location = 'Sweden'
order by 1,2

--Looking at Countries with highest infection rate compared to population

select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/Population)) * 100
	as PercentPopulationInfected
From PortfolioCaseOne..CovidDeaths$
group by location, population
order by PercentPopulationInfected desc

-- Show Countries with the Highest Death Count per Population
Select location, MAX(total_deaths) as TotalDeathCount
from PortfolioCaseOne..CovidDeaths$
group by location
order by TotalDeathCount desc

-- Issue with data type for total_deaths, so i have to cast  as INT
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioCaseOne..CovidDeaths$
group by location
order by TotalDeathCount desc

-- Issue with data, location is showing continents where continent colums is null
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioCaseOne..CovidDeaths$
where continent is not null
group by location
order by TotalDeathCount desc

-- CONTINENT BREAKDOWN

-- Showing continent with highest death count per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioCaseOne..CovidDeaths$
where continent is not null
group by continent
order by TotalDeathCount desc


--select location, MAX(cast(total_deaths as int)) as TotalDeathCount
--from PortfolioCaseOne..CovidDeaths$
--where continent is null
--group by location
--order by TotalDeathCount desc


--GLOBAL NUMBERS

-- Total global cases & deaths
-- as before new_cases is wrong data time thus casting as int
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from PortfolioCaseOne..CovidDeaths$
where continent is not null
order by 1,2

--Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
--	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
--from PortfolioCaseOne..CovidDeaths$
--where continent is not null
--group by date
--order by 1,2

 

 -- Starting working with CovidVaccinations

 -- Joining CovidDeaths with CovidVaccinations
 
Select *
From PortfolioCaseOne..CovidDeaths$ dea
join PortfolioCaseOne..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date

-- Looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioCaseOne..CovidDeaths$ dea
join PortfolioCaseOne..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3	

-- Creating a total vaccinations for each location by date. (Rolling Count)

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.Date) 
	as RollingPeopleVaccinated
From PortfolioCaseOne..CovidDeaths$ dea
Join PortfolioCaseOne..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3 

-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- Use CTE

with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.Date) 
	as RollingPeopleVaccinated
From PortfolioCaseOne..CovidDeaths$ dea
Join PortfolioCaseOne..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3 
)
select *, (RollingPeopleVaccinated/population)*100 as PercentPopulationVaccinated
from PopvsVac

-- What percent of Swedish population is vaccinated

with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.Date) 
	as RollingPeopleVaccinated
From PortfolioCaseOne..CovidDeaths$ dea
Join PortfolioCaseOne..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.location = 'Sweden' 
--order by 2,3 
)
select *, (RollingPeopleVaccinated/population)*100 as PercentPopulationVaccinated
from PopvsVac
-- Interesing enough the data is incorret, we know that sweden began their vaccination earlier than 2021-08-04
-- What could be the proplem? 


-- Temp Table

DROP Table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.Date) 
	as RollingPeopleVaccinated
From PortfolioCaseOne..CovidDeaths$ dea
Join PortfolioCaseOne..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3 

select *, (RollingPeopleVaccinated/population)*100 as PercentPopulationVaccinated
from #PercentPopulationVaccinated


-- Creating a view to store data for later visualization

CREATE VIEW PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.Date) 
	as RollingPeopleVaccinated
From PortfolioCaseOne..CovidDeaths$ dea
Join PortfolioCaseOne..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null


Select *
From PercentPopulationVaccinated