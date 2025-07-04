**AdInsight Analytics: Case Study Questions**

The following are core business questions designed to be explored using SQL queries and logical reasoning. These will help AdInsight Analytics gain actionable insights into customer behavior and interest segmentation.

---

### Data Exploration and Cleansing

1. Update the `month_year` column in `adinsight_analytics.interest_metrics` to be of `DATE` type, with values representing the first day of each month.
2. Count the total number of records for each `month_year` in the `interest_metrics` table, sorted chronologically, ensuring that NULL values (if any) appear at the top.
3. Based on your understanding, what steps should be taken to handle NULL values in the `month_year` column?
4. How many `interest_id` values exist in `interest_metrics` but not in `interest_map`? And how many exist in `interest_map` but not in `interest_metrics`?
5. Summarize the `id` values from the `interest_map` table by total record count.
6. What type of join is most appropriate between the `interest_metrics` and `interest_map` tables for analysis? Justify your approach and verify it by retrieving data where `interest_id = 21246`, including all columns from `interest_metrics` and all except `id` from `interest_map`.
7. Are there any rows in the joined data where `month_year` is earlier than `created_at` in `interest_map`? Are these values valid? Why or why not?

---

### Interest Analysis

8. Which interests appear consistently across all `month_year` values in the dataset?
9. Calculate the cumulative percentage of interest records starting from those present in 14 months. What is the `total_months` value where the cumulative percentage surpasses 90%?
10. If interests with `total_months` below this threshold are removed, how many records would be excluded?
11. Evaluate whether removing these lower-coverage interests is justified from a business perspective. Provide a comparison between a segment with full 14-month presence and one that would be removed.
12. After filtering out lower-coverage interests, how many unique interests remain for each month?

---

### Segment Analysis

13. From the filtered dataset (interests present in at least 6 months), identify the top 10 and bottom 10 interests based on their maximum `composition` value. Also, retain the corresponding `month_year`.
14. Identify the five interests with the lowest average `ranking` value.
15. Determine the five interests with the highest standard deviation in their `percentile_ranking`.
16. For the five interests found in the previous step, report the minimum and maximum `percentile_ranking` values and their corresponding `month_year`. What trends or patterns can you infer from these fluctuations?
17. Based on composition and ranking data, describe the overall customer profile represented in this segment. What types of products/services should be targeted, and what should be avoided?

---

### Index Analysis

18. Calculate the average composition for each interest by dividing `composition` by `index_value`, rounded to 2 decimal places.
19. For each month, identify the top 10 interests based on this derived average composition.
20. Among these top 10 interests, which interest appears most frequently?
21. Calculate the average of these monthly top 10 average compositions across all months.
22. From September 2018 to August 2019, calculate a 3-month rolling average of the highest average composition. Also, include the top interest names for the current, 1-month-ago, and 2-months-ago periods.
23. Provide a plausible explanation for the month-to-month changes in the top average composition. Could it indicate any risks or insights into AdInsight’s business model?

---

### Sample Output for Rolling Average (Q22)

| month\_year | interest\_name             | max\_index\_composition | 3\_month\_moving\_avg | 1\_month\_ago                    | 2\_months\_ago                   |
| ----------- | -------------------------- | ----------------------- | --------------------- | -------------------------------- | -------------------------------- |
| 2018-09-01  | Work Comes First Travelers | 8.26                    | 7.61                  | Las Vegas Trip Planners: 7.21    | Las Vegas Trip Planners: 7.36    |
| 2018-10-01  | Work Comes First Travelers | 9.14                    | 8.20                  | Work Comes First Travelers: 8.26 | Las Vegas Trip Planners: 7.21    |
| 2018-11-01  | Work Comes First Travelers | 8.28                    | 8.56                  | Work Comes First Travelers: 9.14 | Work Comes First Travelers: 8.26 |
| ...         | ...                        | ...                     | ...                   | ...                              | ...                              |

---
