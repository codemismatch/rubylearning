# Rubylearning SQL v0.1 – Design Notes

## Goals

- Provide a **browser‑only SQL runtime** for rubylearning.in, similar in spirit to the current Ruby WASM playground.
- Keep it **lightweight**: no SQLite/WASM; small JS footprint suitable for course exercises.
- Support **basic to intermediate SQL lessons**, not the full SQL spec.
- Use it both as:
  - The **teaching runtime** for SQL courses (students write queries and see results).
  - An optional **infra layer** for small, structured data in the site (e.g. learner state, course metadata experiments).

## Runtime Architecture

### Storage Layer

- Use **IndexedDB via Dexie.js** as the storage engine:
  - One logical database per origin (e.g. `rubylearningSql`).
  - Tables defined via Dexie schemas, e.g.:
    - `chapters(path PRIMARY KEY, scrollPercent, visited, ...)`
    - `practiceItems(chapterPath, index, complete)`
    - `examples(chapterPath, index, executed)`
  - For SQL course content, each lesson can define its own schema and seed data.

### SQL Parsing

- Use **`@antscorp/js-sql-parser`** as the SQL → AST front‑end:
  - Accept a query string from the UI.
  - Parse into an AST describing `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `WHERE`, `ORDER BY`, `LIMIT`, etc.
  - We explicitly support only a **documented subset** of SQL (see “Language Subset v0.1”).

### Execution Pipeline

`runSql(sql, context)` will roughly:

1. Parse the SQL with `js-sql-parser` into an AST.
2. Validate that the AST fits the **supported subset**.
3. Map AST nodes to Dexie operations or in‑memory operations:
   - `FROM table` → `db[table]` Dexie table.
   - Simple `WHERE` → Dexie `where(...).equals(...)` when possible, otherwise filter in JS.
   - `ORDER BY` → Dexie `orderBy(field)` or in‑memory sort.
   - `LIMIT` → slice the result array.
4. Return:
   - For `SELECT`: an array of row objects to render as an HTML table.
   - For `INSERT`/`UPDATE`/`DELETE`: `{ rowsAffected, message }` for display.
5. For teaching, we may **reset** the lesson database between runs (deterministic exercises) or allow it to persist (multi‑step challenges).

## Language Subset – Rubylearning SQL v0.1

We deliberately support a small, teachable subset that keeps the engine simple but covers the core course topics.

### Statements

- `SELECT` from a **single table**:
  - `SELECT * FROM table;`
  - `SELECT col1, col2 FROM table;`
  - `SELECT expr AS alias FROM table;`
- `INSERT`:
  - `INSERT INTO table (col1, col2) VALUES (val1, val2);`
- `UPDATE`:
  - `UPDATE table SET col = expr [, col2 = expr2 ...] WHERE ...;`
- `DELETE`:
  - `DELETE FROM table WHERE ...;`

### Expressions & Predicates

- Literals: numbers, strings, `NULL`, booleans.
- Operators:
  - Comparison: `=`, `<>`, `!=`, `<`, `>`, `<=`, `>=`.
  - Logical: `AND`, `OR`, `NOT`.
  - Ranged / set: `BETWEEN`, `NOT BETWEEN`, `IN (...)`, `NOT IN (...)`.
  - Pattern: `LIKE`, `NOT LIKE`.
- Simple arithmetic on columns for SELECT and WHERE:
  - `col + 1`, `col - 1`, `col * 2`, `col / 2`.

### Query Modifiers

- `ORDER BY col [ASC|DESC]`
- `LIMIT n`
- `LIMIT n OFFSET m`

### Out‑of‑Scope (Future Versions)

- Multi‑table joins.
- Aggregates and grouping.
- Subqueries (including `EXISTS`).
- DDL (CREATE TABLE, ALTER TABLE, etc.).

These are still **course topics**, but the underlying “engine” for v0.1 can fake some of them via pre‑canned views or in‑memory evaluation before we support them generically.

## Course Topics – Proposed Order

These topics will be implemented as Rubylearning SQL lessons, backed by the v0.1 runtime. The numbers below are the **intended sequence**, not original IDs.

1. Getting Started  
2. Comments  

**Core SELECT + Filtering**

3. Select  
4. Select specific column  
5. Select multiple data  
6. Select and filter  
7. Less than and greater than  
8. Less than and greater than with equal to  
9. AND & OR  
10. BETWEEN & NOT BETWEEN  
11. IN & NOT IN  
12. NULL value  
13. Handling NULL  
14. LIKE value  
15. NOT LIKE value  

**Projection, DISTINCT, Expressions**

16. DISTINCT operator  
17. AS operator  
18. Using LENGTH  
19. Arithmetic - Operations on columns  
20. Arithmetic - Filtering and Ordering  
21. Selecting modified data from rows  
22. Combining data from columns  

**Ordering & Limiting**

23. ORDER BY  
24. ORDER BY - Ascending and Descending  
25. ORDER BY - More use cases  
26. LIMIT  
27. LIMIT with ordering and offset  

**Aggregates & Grouping (v0.1+: may be partially stubbed)**

28. COUNT operator  
29. SUM and AVG  
30. MAX and MIN  
31. COUNT & DISTINCT  
32. Date functions  
33. GROUP BY - with COUNT  
34. GROUP BY - with other aggregate functions  
35. GROUP BY - more use cases  
36. GROUP BY - multiple columns  
37. GROUP BY - GROUP_CONCAT  

**Joins & Set Operations (likely v0.2 of the engine)**

38. JOINS - INNER JOIN  
39. JOINS - OUTER JOIN  
40. JOINS - SELF JOIN  
41. JOINS - Multiple tables  
42. JOINS - Filtering and Ordering  
43. JOINS - Grouping  
44. JOINS - Complex grouping  
45. JOINS - Cartesian Product  
46. UNION  
47. INTERSECT and EXCEPT  

**Subqueries (future engine capabilities)**

48. Subqueries  
49. Subqueries in FROM clause  
50. Correlated subqueries  
51. Subqueries - EXISTS operator  
52. SQL statements with subqueries  

**Schema & Data Modification (DDL/DML)**

53. Creating tables  
54. Inserting data in tables  
55. Executing multiple statements  
56. Column constraints - NOT NULL and UNIQUE  
57. Column constraints - DEFAULT and CHECK  
58. Table constraints - PRIMARY KEY  
59. PRIMARY KEY - AUTOINCREMENT  
60. Table constraints - FOREIGN KEY  
61. Updating data in tables  
62. Deleting data from tables  
63. Adding and updating columns  
64. Renaming and deleting tables  
65. VIEWS  

## Implementation Phasing

1. **Engine v0.1**  
   - Implement single‑table `SELECT`/`INSERT`/`UPDATE`/`DELETE` with WHERE/ORDER/LIMIT.  
   - Backed by Dexie + `@antscorp/js-sql-parser`.  
   - Wire into a simple “Run SQL” UI that mirrors Ruby exec.

2. **Basic Course Lessons**  
   - Implement topics 1–27 using only v0.1 features.  
   - Seed databases per lesson; show tabular results and “rows affected”.

3. **Aggregates / GROUP BY & Beyond (v0.1+/0.2)**  
   - Extend executor with COUNT/SUM/AVG/MIN/MAX and GROUP BY support.  
   - Gradually add JOIN and subquery support as needed for later lessons.

This file is the working design reference for the Rubylearning SQL runtime and curriculum; update it as the engine and course evolve.

