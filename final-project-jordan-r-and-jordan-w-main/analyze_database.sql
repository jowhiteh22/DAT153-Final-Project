/*
Assignment: Final Project
Course:     DAT 153
Term:       Spring 2025
Author:     Jordan Whitehouse & Jordan Reed
Script:     Database Analysis Script


 Q1: Basic SELECT query — List all celebrities from Tennessee
*/
SELECT celebrity_name, celebrity_industry, celebrity_homestate
FROM celebrity
WHERE celebrity_homestate = 'Tennessee'
ORDER BY celebrity_name;

-----------------------------------------------------------------------------------------------------
/* Q2: INNER JOIN — List all celebrity names with their pro partner names for each season */
SELECT c.celebrity_name, p.pro_name, s.season_number
FROM celebrity c
         JOIN celebrity_season cs ON c.celebrity_id = cs.celebrity_id
         JOIN pros p ON cs.pro_id = p.pro_id
         JOIN season s ON cs.season_id = s.season_id
ORDER BY season_number, c.celebrity_name;

------------------------------------------------------------------------------------------------------
/* Q3: LEFT JOIN — List all the pros in alphabetical order and the celebrity they were paired with for each season they were a pro */
SELECT p.pro_name,
       c.celebrity_name,
       s.season_number
FROM pros p
         LEFT JOIN celebrity_season cs ON p.pro_id = cs.pro_id
         LEFT JOIN celebrity c ON cs.celebrity_id = c.celebrity_id
         LEFT JOIN season s ON cs.season_id = s.season_id
ORDER BY p.pro_name, s.season_number asc;

-----------------------------------------------------------------------------------------------
/* Q4: Aggregation — Count how many celebrities each pro has been partnered with order by the pro with the most celeb partners to least */
SELECT p.pro_name, COUNT(DISTINCT cs.celebrity_id) AS total_celebrities
FROM pros p
         JOIN celebrity_season cs ON p.pro_id = cs.pro_id
GROUP BY p.pro_name
ORDER BY total_celebrities DESC;

-------------------------------------------------------------------------------------------------------
/* Q5: GROUP BY + HAVING — List seasons that had more than 10 different celebrities compete */
SELECT s.season_number, COUNT(DISTINCT cs.celebrity_id) AS num_celebrities
FROM season s
         JOIN celebrity_season cs ON s.season_id = cs.season_id
GROUP BY s.season_number
HAVING COUNT(DISTINCT cs.celebrity_id) > 10
ORDER BY num_celebrities ASC;

-------------------------------------------------------------------------------------------------
/* Q6: SET OPERATOR — Find celebrities who danced either Jive or Paso Doble, but not both */
(SELECT DISTINCT c.celebrity_name
 FROM celebrity c
          JOIN celebrity_season cs ON c.celebrity_id = cs.celebrity_id
          JOIN dances_performed dp ON cs.celebrity_season_id = dp.celebrity_season_id
 WHERE dp.dance_id = '3'
 EXCEPT
 SELECT DISTINCT c.celebrity_name
 FROM celebrity c
          JOIN celebrity_season cs ON c.celebrity_id = cs.celebrity_id
          JOIN dances_performed dp ON cs.celebrity_season_id = dp.celebrity_season_id
 WHERE dp.dance_id = 6)
UNION
(SELECT DISTINCT c.celebrity_name
 FROM celebrity c
          JOIN celebrity_season cs ON c.celebrity_id = cs.celebrity_id
          JOIN dances_performed dp ON cs.celebrity_season_id = dp.celebrity_season_id
 WHERE dp.dance_id = '6'
 EXCEPT
 SELECT DISTINCT c.celebrity_name
 FROM celebrity c
          JOIN celebrity_season cs ON c.celebrity_id = cs.celebrity_id
          JOIN dances_performed dp ON cs.celebrity_season_id = dp.celebrity_season_id
 WHERE dp.dance_id = 3)
ORDER BY celebrity_name;

---------------------------------------------------------------------------------------------------------------------------------
/* Q7: Window Function — Show each celebrity’s total score per week along with their cumulative score (running total) across weeks in each season. */
SELECT ts.celebrity_name,
       ts.season_number,
       ts.week,
       ts.total_score,
       SUM(ts.total_score) OVER (
           PARTITION BY ts.celebrity_season_id
           ORDER BY ts.week
           ) AS cumulative_score
FROM total_scores ts;

---------------------------------------------------------------------------------------------------------------------------------
/* Q8: Sub-query — Find the names of celebrities who scored higher than the average total weekly score across all seasons. */
SELECT DISTINCT ts.celebrity_name
FROM total_scores ts
WHERE ts.total_score > (SELECT AVG(total_score)
                        FROM total_scores);

----------------------------------------------------------------------------------------------------------------
/* Q9: CTE — For each season, find the celebrity who had the highest total score in any single week. */
WITH max_scores AS (SELECT season_number,
                           celebrity_name,
                           week,
                           total_score,
                           RANK() OVER (PARTITION BY season_number ORDER BY total_score DESC) AS score_rank
                    FROM total_scores)
SELECT season_number,
       celebrity_name,
       week,
       total_score
FROM max_scores
WHERE score_rank = 1
ORDER BY season_number, week ASC;

------------------------------------------------------------------------------------------------------------
/* Q10: Get the average score (all judges combined) for each dance style, sorted by highest to lowest average. */
SELECT ds.dance_name,
       ROUND(AVG(s.judge1_score + s.judge2_score + s.judge3_score + COALESCE(s.judge4_score, 0)), 2) AS avg_total_score,
       COUNT(*)                                                                                      AS num_performances
FROM dances_performed dp
         JOIN dance_styles ds ON dp.dance_id = ds.dance_id
         JOIN score s ON dp.celebrity_season_id = s.celebrity_season_id AND dp.week = s.week
GROUP BY ds.dance_name
ORDER BY avg_total_score DESC;

------------------------------------------------------------------------------------------------------
/* Q11: Identify the top 5 most paired pros who competed in Season 33 and count how many times they’ve been assigned to a celebrity across all seasons, and calculates their average placement. */
SELECT p.pro_name,
       COUNT(cs_all.celebrity_season_id) AS total_celebs_coached,
       ROUND(AVG(cs_all.placement), 2)   AS avg_placement
FROM pros p
         JOIN celebrity_season cs33
              ON p.pro_id = cs33.pro_id
         JOIN season s33
              ON cs33.season_id = s33.season_id
         JOIN celebrity_season cs_all
              ON p.pro_id = cs_all.pro_id
WHERE s33.season_number = 33
GROUP BY p.pro_name
ORDER BY total_celebs_coached DESC
LIMIT 5;

-------------------------------------------------------------------------------------------------
/* Q12: Find all the hosts and judges for season 31 */
(SELECT 'Host' AS role, h.host_name AS name
 FROM hosts h
          JOIN host_season sh ON h.host_id = sh.host_id
          JOIN season s ON sh.season_id = s.season_id
 WHERE s.season_number = 31)
UNION
(SELECT 'Judge' AS role, j.judge_name AS name
 FROM judges j
          JOIN judges_score js ON j.judge_id = js.judge_id
          JOIN score sc ON js.score_id = sc.score_id
          JOIN celebrity_season cs ON cs.celebrity_season_id = sc.celebrity_season_id
          JOIN season s ON cs.season_id = s.season_id
 WHERE s.season_number = 31
 GROUP BY j.judge_name);

-------------------------------------------------------------------------------------------------------------
/* Q13: Create a query that is pivoted to be one row per season with host_1 and host_2 names */
SELECT hs_pair.host_season_id,
       s.season_id,
       s.season_number,
       h1.host_name AS host_1_name,
       h2.host_name AS host_2_name
FROM (SELECT MIN(hs1.host_season_id) AS host_season_id,
             hs1.season_id,
             MIN(hs1.host_id)        AS host_id_1,
             MAX(hs1.host_id)        AS host_id_2
      FROM host_season hs1
      GROUP BY hs1.season_id) AS hs_pair
         JOIN hosts h1 ON hs_pair.host_id_1 = h1.host_id
         JOIN hosts h2 ON hs_pair.host_id_2 = h2.host_id
         JOIN season s ON hs_pair.season_id = s.season_id
ORDER BY s.season_number;

---------------------------------------------------------------------------------------------
/* Q14:For each celebrity in each season, return:
   - Celebrity name
   - Season number
   - Professional partner
   - Average weekly total score (across judges)
   - Number of unique dances performed
   - Finale viewership for that season
*/
SELECT
    c.celebrity_name,
    s.season_number,
    p.pro_name AS professional_partner,
    ROUND(AVG(ts.total_score), 2) AS average_weekly_score,
    COUNT(DISTINCT dp.week) AS num_unique_dance_weeks,
    s.finale_views
FROM
    celebrity_season cs
JOIN celebrity c ON cs.celebrity_id = c.celebrity_id
JOIN pros p ON cs.pro_id = p.pro_id
JOIN season s ON cs.season_id = s.season_id
LEFT JOIN total_scores ts ON cs.celebrity_season_id = ts.celebrity_season_id
LEFT JOIN dances_performed dp ON cs.celebrity_season_id = dp.celebrity_season_id
GROUP BY
    c.celebrity_name,
    s.season_number,
    p.pro_name,
    s.finale_views
ORDER BY
    average_weekly_score DESC;

--------------------------------------------------------------------------------------------------------------
/* Q15 - Part 1: Show how scores changed week by week for all top 3 finalists in Season 5, along with their names and total weekly score. */
SELECT c.celebrity_name,
       s.week,
       (s.judge1_score + s.judge2_score + s.judge3_score + COALESCE(s.judge4_score, 0)) AS total_weekly_score
FROM celebrity_season cs
         JOIN celebrity c ON cs.celebrity_id = c.celebrity_id
         JOIN season se ON cs.season_id = se.season_id
         JOIN score s ON cs.celebrity_season_id = s.celebrity_season_id
WHERE se.season_number = 5
  AND cs.placement <= 3
ORDER BY c.celebrity_name, s.week;

/* Q15 - Part 2: Use of custom PROCEDURE — Call the procedure to get Shawn Johnson's full dance history  */
-- Note use of custom view total_scores can be seen in the above examples!
CALL get_celebrity_dance_history('Shawn Johnson');

/* Q15 - Part 3: Return the placement, season, and celebrity partner for Derek Hough in Season 15 */
SELECT * FROM pro_seasons('Derek Hough', 15);
