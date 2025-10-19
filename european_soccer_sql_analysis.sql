/* Subqueries */

---add many subqueries as you want as in select , from , where 
--Your query calculates the average goals per stage in a season and then filters stages that have above-average goals
SELECT 
    s.stage,
    ROUND(s.avg_goals, 2) AS avg_goals
FROM 
    (SELECT
         stage,
         AVG(home_goal + away_goal) AS avg_goals
     FROM match
     WHERE season = '2012/2013'
     GROUP BY stage
     ) AS s
WHERE 
    s.avg_goals > (SELECT AVG(home_goal + away_goal) 
                   FROM match 
                   WHERE season = '2012/2013');


 ----simplified query for the above problem 
 SELECT 
    stage,
    ROUND(AVG(home_goal + away_goal), 2) AS avg_goals
FROM match
WHERE season = '2012/2013'
GROUP BY stage
HAVING AVG(home_goal + away_goal) > 
       (SELECT AVG(home_goal + away_goal) 
        FROM match 
        WHERE season = '2012/2013');


/* Correlated Queries */

--Which match stages tend to have a higher than average number of goals scored?

SELECT 
    main.country_id,
    main.date,
    main.home_goal,
    main.away_goal,
    (main.away_goal + main.home_goal ) as total_goals,
FROM match AS main
WHERE 
    (home_goal + away_goal) > 
        (SELECT AVG((sub.home_goal + sub.away_goal) * 3) as avg_calculated
         FROM match AS sub
         WHERE main.country_id = sub.country_id);

--- if you want to see the avg score too you should use cte 
with avg_per_country as (
    select 
        country_id,
        AVG((home_goal + away_goal) * 3) as avg_calculated
    FROM match
    GROUP BY country_id 
)
SELECT 
    m.country_id,
    m.date,
    m.home_goal,
    m.away_goal,
    (m.home_goal + m.away_goal) AS total_goals,
    a.avg_calculated
FROM match AS m
JOIN avg_per_country AS a
    ON m.country_id = a.country_id
WHERE (m.home_goal + m.away_goal) > a.avg_calculated;         


-- correlated subquery with multiple conditions
--  this exmaple finds the highest scoring match for each country in each season
SELECT 
    main.country_id,
    main.date,
    main.home_goal,
    main.away_goal
FROM match AS main
WHERE 
    (home_goal + away_goal) =
        (SELECT MAX(sub.home_goal + sub.away_goal)
         FROM match AS sub
         WHERE main.country_id = sub.country_id
               AND main.season = sub.season);


--- using cte for showing the seasons and max score details               
WITH max_goals AS (
    SELECT 
        country_id,
        season,
        MAX(home_goal + away_goal) AS max_total_goals
    FROM match
    GROUP BY country_id, season
)
SELECT 
    m.country_id,
    m.season,
    m.date,
    m.home_goal,
    m.away_goal,
    (m.home_goal + m.away_goal) AS total_goals,
    g.max_total_goals
FROM match AS m
JOIN max_goals AS g
    ON m.country_id = g.country_id
   AND m.season = g.season
   AND (m.home_goal + m.away_goal) = g.max_total_goals
ORDER BY m.country_id, m.season;

--Nested sub queries 
--Example calculte the diffrence bewteen each month's total goals and monthly average of goals scored 
SELECT 
    EXTRACT(MONTH FROM TO_DATE(date, 'MM/DD/YY HH24:MI')) AS month,
    SUM(home_goal + away_goal) AS total_goals,
    (SELECT AVG(total_goals) 
     FROM (
         SELECT SUM(home_goal + away_goal) AS total_goals
         FROM match
         GROUP BY EXTRACT(MONTH FROM TO_DATE(date, 'MM/DD/YY HH24:MI'))
     ) AS monthly_totals) AS avg_monthly_goals
FROM match
GROUP BY EXTRACT(MONTH FROM TO_DATE(date, 'MM/DD/YY HH24:MI'));



--- using ctes 
-- Step 1: Clean the date column
WITH matches_clean AS (
    SELECT 
        TO_DATE(date, 'MM/DD/YY HH24:MI') AS match_date,
        home_goal,
        away_goal
    FROM match
),

-- Step 2: Calculate total goals per month
monthly_totals AS (
    SELECT 
        EXTRACT(MONTH FROM match_date) AS month,
        SUM(home_goal + away_goal) AS total_goals
    FROM matches_clean
    GROUP BY EXTRACT(MONTH FROM match_date)
),

-- Step 3: Calculate overall average of monthly totals
overall_avg AS (
    SELECT AVG(total_goals) AS avg_monthly_goals
    FROM monthly_totals
)

-- Step 4: Final selection with difference
SELECT 
    m.month,
    m.total_goals,
    o.avg_monthly_goals,
    m.total_goals - o.avg_monthly_goals AS difference
FROM monthly_totals AS m
CROSS JOIN overall_avg AS o
ORDER BY m.month;


--- Correlated subqueries in from clause 
--Find the average number of matches per season where a team scored 5 or more goals, and see how this differs by country
SELECT 
    country_id,
    AVG(matches_per_season) AS avg_matches_per_season
FROM (
    SELECT 
        country_id,
        season,
        COUNT(*) AS matches_per_season
    FROM match
    WHERE home_goal + away_goal >= 5
    GROUP BY country_id, season
) AS subquery
GROUP BY country_id;

--with cte 
WITH matches_per_season AS (
    SELECT 
        country_id,
        season,
        COUNT(*) AS matches_count
    FROM match
    WHERE home_goal + away_goal >= 5
    GROUP BY country_id, season
)
SELECT 
    country_id,
    AVG(matches_count) AS avg_matches_per_season
FROM matches_per_season
GROUP BY country_id;


-- Window Functions 
SELECT 
    m.id,
    c.name AS country,
    m.season,
    m.home_goal,
    m.away_goal,
    AVG(m.home_goal + m.away_goal) OVER() AS overall_avg
FROM match AS m
LEFT JOIN country AS c ON m.country_id = c.id;

---- 
SELECT 
    m.id,
    c.name AS country,
    m.season,
    m.home_goal,
    m.away_goal,
    AVG(m.home_goal + m.away_goal) OVER() AS overall_avg
FROM match AS m
LEFT JOIN country AS c ON m.country_id = c.id;

 --- Descending order rank 
SELECT 
    l.name AS league,
    AVG(m.home_goal + m.away_goal) AS avg_goals,
    RANK() OVER(ORDER BY AVG(m.home_goal + m.away_goal) DESC) AS league_rank
FROM league AS l
LEFT JOIN match AS m 
ON l.id = m.country_id
WHERE m.season = '2011/2012'
GROUP BY l.name
ORDER BY league_rank;


-- Over with partiton 
SELECT 
    l.name AS league,
    AVG(m.home_goal + m.away_goal) AS avg_goals,
    RANK() OVER(ORDER BY AVG(m.home_goal + m.away_goal) DESC) AS league_rank
FROM league AS l
LEFT JOIN match AS m 
ON l.id = m.country_id
WHERE m.season = '2011/2012'
GROUP BY l.name
ORDER BY league_rank;


--- Partition by a column

SELECT 
    date,
    season,
    home_goal,
    away_goal,
    CASE WHEN hometeam_id = 8673 THEN 'home' 
         ELSE 'away' END AS warsaw_location,
    AVG(home_goal) OVER(PARTITION BY season) AS season_homeavg,
    AVG(away_goal) OVER(PARTITION BY season) AS season_awayavg
FROM match
WHERE 
    hometeam_id = 8673 
    OR awayteam_id = 8673
ORDER BY (home_goal + away_goal) DESC;

--- Partition by multiple columns 
SELECT 
    date,
    season,
    home_goal,
    away_goal,
    CASE WHEN hometeam_id = 8673 THEN 'home' 
         ELSE 'away' END AS warsaw_location,
    AVG(home_goal) OVER(PARTITION BY season, 
          EXTRACT(MONTH FROM TO_DATE(date, 'MM/DD/YY HH24:MI'))) AS season_mo_home,
    AVG(away_goal) OVER(PARTITION BY season, 
         EXTRACT(MONTH FROM TO_DATE(date, 'MM/DD/YY HH24:MI'))) AS season_mo_away
FROM match
WHERE 
    hometeam_id = 8673 
    OR awayteam_id = 8673
ORDER BY (home_goal + away_goal) DESC;

--sliding windows 
SELECT 
    date,
    home_goal,
    away_goal,
    SUM(home_goal) OVER(ORDER BY date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
    AVG(home_goal) OVER(ORDER BY date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_avg
FROM match
WHERE 
    hometeam_id = 9908 
    AND season = '2011/2012';

--- reverse running totals 
SELECT 
    date,
    home_goal,
    away_goal,
    SUM(home_goal) OVER(ORDER BY date DESC
        ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS running_total,
    AVG(home_goal) OVER(ORDER BY date DESC
        ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS running_avg
FROM match
WHERE 
    awayteam_id = 9908 
    AND season = '2011/2012';




----- using Common table Expression for Home and away teams 
-- identify matches where manchester united played as the home or away team 
WITH home AS (
  SELECT m.id, t.team_long_name,
      CASE 
          WHEN m.home_goal > m.away_goal THEN 'MU Win'
          WHEN m.home_goal < m.away_goal THEN 'MU Loss' 
          ELSE 'Tie' 
      END AS outcome
  FROM match AS m
  LEFT JOIN team AS t ON m.hometeam_id = t.team_api_id
),
away AS (
  SELECT m.id, t.team_long_name,
      CASE 
          WHEN m.home_goal > m.away_goal THEN 'MU Loss'
          WHEN m.home_goal < m.away_goal THEN 'MU Win' 
          ELSE 'Tie' 
      END AS outcome
  FROM match AS m
  LEFT JOIN team AS t ON m.awayteam_id = t.team_api_id
)
SELECT DISTINCT
    m.date,
    home.team_long_name AS home_team,
    away.team_long_name AS away_team,
    m.home_goal, m.away_goal
FROM match AS m
LEFT JOIN home ON m.id = home.id
LEFT JOIN away ON m.id = away.id
WHERE m.season = '2014/2015'
      AND (home.team_long_name = 'Manchester United' 
           OR away.team_long_name = 'Manchester United');


 ------ rank matches by the absolute goal difference to see how badly manchester united lost each match 
 WITH home AS (
  SELECT m.id, t.team_long_name,
      CASE 
          WHEN m.home_goal > m.away_goal THEN 'MU Win'
          WHEN m.home_goal < m.away_goal THEN 'MU Loss' 
          ELSE 'Tie' 
      END AS outcome
  FROM match AS m
  LEFT JOIN team AS t ON m.hometeam_id = t.team_api_id
),
away AS (
  SELECT m.id, t.team_long_name,
      CASE 
          WHEN m.home_goal > m.away_goal THEN 'MU Loss'
          WHEN m.home_goal < m.away_goal THEN 'MU Win' 
          ELSE 'Tie' 
      END AS outcome
  FROM match AS m
  LEFT JOIN team AS t ON m.awayteam_id = t.team_api_id
)
SELECT DISTINCT
    m.date,
    home.team_long_name AS home_team,
    away.team_long_name AS away_team,
    m.home_goal, m.away_goal,
    RANK() OVER(ORDER BY ABS(home_goal - away_goal) DESC) as match_rank
FROM match AS m
LEFT JOIN home ON m.id = home.id
LEFT JOIN away ON m.id = away.id
WHERE m.season = '2014/2015'
      AND ((home.team_long_name = 'Manchester United' AND home.outcome = 'MU Loss')
      OR (away.team_long_name = 'Manchester United' AND away.outcome = 'MU Loss'));          
