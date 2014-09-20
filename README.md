
```sql
SELECT semver_compare('2.0.0', '2.1.3');
```
```
 semver_compare
----------------
             -1
(1 row)
```

```sql
SELECT semver_compare('6.3.0', '6.3.0+banana');
```
```
 semver_compare
----------------
              0
(1 row)
```

```sql
SELECT some_version LIKE '3.%' AND semver_compare(some_version, '4.0.0') < 0
FROM (VALUES
  ('3.5.0'),
  ('3.99.0'),
  ('4.0.0-rc2')
) x (some_version);
```

```
 ?column?
----------
 t
 t
 f
(3 rows)
```
