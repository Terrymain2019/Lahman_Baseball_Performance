/*1.What range of years does the provided database cover?*/
select yearid from appearances group by yearid order by yearid;
--From 1871 to 2016.

/*2.Name and height of the shortest player in the database, 
How many games did he play in and name of the team for which he played?*/
select * from people;
select playerid, height, namefirst || ' ' || namelast as full_name, namegiven 
from people 
group by playerid 
order by height LIMIT 2;

--shortest player is Eddie Gaedel (Edward Carl),gaedeed01 and he is 43 inches or 3.58 ft. 
select * from appearances;
/*select p.playerid, a.teamid, a.yearid
from people as p
join appearances as a
on p.playerid = a.playerid 
where playerid = 'gaedeed01'
group by a.yearid, a.teamid, p.playerid;*/

select a.playerid,  a.yearid, t.teamid, t.name, t.g
from appearances as a
join teams as t
on a.yearid = t.yearid 
where playerid = 'gaedeed01'
group by t.g, a.playerid, t.teamid, t.name, a.yearid
order by t.g;
--Eddie played 16 games in 1951.

/*3. players in the database who played at Vanderbilt University,
total salary earned and player who earned the most money in the majors*/
select p.namefirst, p.namelast, p.namegiven, sl.playerid, SUM(sl.salary) as total_salary
from people as p
join salaries as sl
on p.playerid = sl.playerid
where p.playerid in 
	(select c.playerid
	from schools as s
	join collegeplaying as c
	on s.schoolid = c.schoolid
	where schoolname = 'Vanderbilt University'
	group by c.playerid
	order by c.playerid)
group by p.namefirst, p.namelast, p.namegiven, sl.playerid
order by total_salary desc;
--David Price earned the most $81,851,296.

/*4. Using the fielding table, group players into three groups based on their position: 
label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", 
and those with position "P" or "C" as "Battery". 
Determine the number of putouts made by each of these three groups in 2016.*/
select * from fielding;
select yearid, sum(po) as total_putouts,
case when pos in ('OF') then 'Outfield'
	when pos in ('SS', '1B', '2B', '3B') then 'Infield'
	when pos in ('P') or pos in ('C') then 'Battery' end as positions
from fielding 
where yearid = '2016' 
group by yearid, positions
order by total_putouts desc;

/*5. average number of strikeouts per game by decade since 1920. Do the same for home runs per game. 
Do you see any trends?*/
--first option.
SELECT yearid/10*10 as Decade
     , round(AVG(so), 2) as strikeouts, round(AVG(hr), 2) as homeruns
FROM batting
WHERE yearid >= 1920
GROUP BY Decade
ORDER BY Decade;
--total games/total strikeouts to get avg strikeouts per game?
--second option.
select * from batting;
SELECT yearid/10*10 as Decade, 
sum(g) as total_games, sum(so) as total_strikeouts, sum(hr) as total_homeruns,
(sum(g)/sum(so)) as avg_strikeouts, (sum(g)/sum(hr)) as avg_homeruns
FROM batting
WHERE yearid >= 1920
GROUP BY Decade; 
--ORDER BY avg_strikeouts, avg_homeruns;
--Final option
select round(sum(hr)/(sum(g)::numeric/2),2) as avg_hr_per_game,
round(sum(so)/(sum(g)::numeric/2),2) as avg_so_per_game,
yearid/10*10 as Decade
from teams
where yearid >=1920
group by Decade;

/*6. The player who had the most success stealing bases in 2016, 
where success is measured as the percentage of stolen base attempts which are successful.*/
select p.namegiven, b.playerid, yearid, sum(b.sb) as total_stolenbases, sum(b.cs) as total_caughtstealing,
cast(sum(b.sb) as float)/cast(sum(b.sb+b.cs) as float) *100 as success_base_perc 
--round((b.sb/(b.sb+b.cs)::numeric)*100, 3) as success_base_perc
from batting as b
inner join people as p
on b.playerid = p.playerid
where yearid = '2016' and sb>=20 
group by yearid, b.playerid, p.namegiven
order by success_base_perc desc;
/*Christopher Scott had the most success stealing bases in 2016 
He had 21 total stolen bases, 2 caught stealing and 91% of stolen base attempts which were successful*/  


/*7a. From 1970 – 2016, find the largest number of wins for a team that did not win the world series?*/
select * from teams;
select rank, yearid, sum(w) as wins, wswin, teamid
from teams
where wswin = 'N' and yearid between 1970 and 2016
group by wswin, teamid, yearid, rank
order by wins DESC
limit 1;
--SEA had the most wins but did not win the world series.

/*7b. What is the smallest number of wins for a team that did win the world series?*/
select sum(w) as wins, wswin, yearid, teamid
from teams
where wswin = 'Y' and yearid between 1970 and 2016
group by wswin, teamid, yearid
order by wins;
--LAN had the least number of wins but have won the world series in 1981.

/*7c. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
What percentage of the time?*/
with most_wins_by_year as (
with win_ranks as (
select yearid, teamid, w, wswin,
row_number() over (partition by yearid order by w desc, wswin desc) as rank
from teams
where yearid between 1970 and 2016)
	
select yearid, teamid
from win_ranks
where rank = 1),
ws_wins_by_year as 

(select yearid, teamid
 from teams
 where wswin = 'Y'
 and yearid between 1970 and 2016
 group by yearid, teamid)
 
select count(distinct mwby.yearid),
       2017 - 1970 - 1 as total_years,
       round(count(distinct mwby.yearid) / (2017 - 1970 - 1)::numeric, 2) * 100 as pct_did_win
from most_wins_by_year mwby
inner join ws_wins_by_year wwby
    on mwby.yearid = wwby.yearid
           AND mwby.teamid = wwby.teamid;

/*8a. Find the teams and parks which had the top 5 average attendance per game in 2016.
(Average attendance is defined as total attendance divided by number of games)*/
select * from homegames;
select h.year, h.team, h.park, p.park_name, ((sum(h.attendance))/h.games) as avg_attendance
from homegames as h
inner join parks as p
on h.park = p.park
where year = '2016'
group by h.year,h.team, h.park, h.games, p.park_name
having sum(h.games) >=10
order by avg_attendance desc
limit 5;

/*8b. lowest 5 average attendance per game in 2016.*/ 
select h.year, h.team, h.park, p.park_name, ((sum(h.attendance))/h.games) as avg_attendance
from homegames as h
inner join parks as p
on h.park = p.park
where year = '2016'
group by h.year,h.team, h.park, h.games, p.park_name
having sum(h.games) >=10
order by avg_attendance
limit 5;

/*Question 9
Which managers have won the TSN Manager of the Year award in both the National League (NL) 
and the American League (AL)?*/
with nl_managers as (
select playerid, yearid 
from awardsmanagers
where lgid = 'NL' and awardid = 'TSN Manager of the Year'
group by playerid, yearid
),
al_managers as(
select playerid, yearid 
from awardsmanagers
where lgid = 'AL' and awardid = 'TSN Manager of the Year'
group by playerid, yearid
)
select al_m.playerid, p.namefirst || ' ' || p.namelast as full_name, m.yearid, m.teamid
from nl_managers as nl_m
inner join al_managers al_m using(playerid)
inner join people as p using (playerid)
left join managers as m on p.playerid = m.playerid and (m.yearid = al_m.yearid or m.yearid = nl_m.yearid)
group by al_m.playerid, full_name, m.yearid, teamid
order by al_m.playerid, yearid;
--When Davey Johnson won NL and AL awards he managed Baltimore and Washington teams. 
--When Jim Leyland won the NL and AL awards he managed Pittsburg and Detroit teams. 







