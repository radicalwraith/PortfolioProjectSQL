select *
from PortfolioProject..[covid-deaths]
where continent is not null
order by 3,4

--select *
--from PortfolioProject..[covid-vaccs]
--order by 3,4

-- Selecting the data we will be using

select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..[covid-deaths]
order by 1,2


-- Looking at total cases vs total deaths
-- shows the likelihood of dying to covid in a country
select Location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0))*100 as DeathPercentage
from PortfolioProject..[covid-deaths]
order by 1,2
 
-- Looking at the total cases vs the population in India
select Location, date, total_cases, population, (total_cases/population)*100 as CovidPercentage
from PortfolioProject..[covid-deaths]
where location='India'
order by 1,2

-- Looking at countries with highest infection rate wrt population
select Location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentofPopulationInfected
from PortfolioProject..[covid-deaths]
group by Location, population
order by PercentofPopulationInfected desc

-- Looking at countries with highest death count wrt population
select Location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..[covid-deaths]
where continent is not null
group by Location
order by TotalDeathCount desc


-- showing the continents with the highest death count
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..[covid-deaths]
where continent is not null
group by continent
order by TotalDeathCount desc


-- global numbers
--select date, SUM(new_cases), SUM(new_deaths), SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
--from PortfolioProject..[covid-deaths]
--where continent is not null
--group by date
--order by 1,2

select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/ SUM(NULLIF(new_cases, 0))*100 as DeathPercentage
from PortfolioProject..[covid-deaths]
where continent is not null
--group by date
order by 1,2


-- joining the 2 tables
-- looking at total population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as float)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..[covid-deaths] dea
join PortfolioProject..[covid-vaccs] vac
	on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null
order by 2,3

--using CTE
with PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as float)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..[covid-deaths] dea
join PortfolioProject..[covid-vaccs] vac
	on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null
--order by 2,3
) select *, (RollingPeopleVaccinated/population)*100 from PopvsVac


-- temp table
DROP table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as float)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..[covid-deaths] dea
join PortfolioProject..[covid-vaccs] vac
	on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null

select *, (RollingPeopleVaccinated/population)*100 from #PercentPopulationVaccinated

-- creating a view to store data for later viz
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as float)) OVER (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from PortfolioProject..[covid-deaths] dea
join PortfolioProject..[covid-vaccs] vac
	on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null
--order by 2,3

select * from PercentPopulationVaccinated