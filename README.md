🔁 Think in 3 layers when solving any SQL problem

Whenever you see a question or dataset problem, walk through this mental checklist:

1️⃣ Clarify the goal (what do I need to output?)

Example:

“Find the highest scoring match per country per season.”
→ I need country_id, season, and the match with the most goals.

That tells you your columns and granularity (the level you’re grouping at).

2️⃣ Identify relationships (what level do I aggregate?)

Ask yourself:

Do I need totals per group → use GROUP BY.

Do I need to compare each row to a group → use subquery or CTE + JOIN.

Do I need to pick the top record per group → use MAX() with GROUP BY or window functions.

This step builds the structure of your solution.

3️⃣ Build step-by-step (don’t jump straight to final query)

Start small:

Write a query that gets the basic data.

Then compute the metric (like total goals).

Then group or filter it.

Then, if needed, join it back or filter by max.

Think of it like solving a puzzle one piece at a time — not writing the perfect query from the start.

🧠 Example: Applying this thinking

Problem: Find teams that scored above their season’s average.

1️⃣ Output? → team_id, season, goals.
2️⃣ Relationship? → comparing each team to the season average → needs subquery or CTE.
3️⃣ Steps:

First get AVG(goals) per season.

Then join it to main table.

Then filter where team_goals > avg_goals.

You’ll notice you’re now thinking like SQL, not just memorizing patterns.