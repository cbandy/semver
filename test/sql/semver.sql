-- vim: et:sw=4:ts=4

BEGIN;

\i test/pgtap-core.sql
\i sql/semver.sql

SELECT * FROM no_plan();


-- CREATE TYPE semver;
-- 
-- CREATE OR REPLACE FUNCTION semver_in(text)
-- RETURNS semver AS $$
-- 
--     SELECT
--         CASE
--             WHEN array_length(version_array, 1) = 3
--             THEN version_array::integer[]
--             ELSE ARRAY[version]::integer[]
--         END,
--         prerelease,
--         build
--     FROM (
--         SELECT
--             string_to_array(regexp_matches[1], '.'),
--             regexp_matches[1],
--             regexp_matches[2],
--             regexp_matches[3]
--         FROM regexp_matches($1, '^(.*?)(?:-([[:alnum:].-]+))?(?:\+([[:alnum:].-]+))?$')
--     ) parsed(version_array, version, prerelease, build)
-- 
-- $$ LANGUAGE SQL IMMUTABLE STRICT;
-- 
-- CREATE OR REPLACE FUNCTION semver_out(semver)
-- RETURNS text AS $$
-- 
--     SELECT
--         array_to_string($1.version, '.') ||
--         CASE WHEN $1.prerelease IS NULL THEN '' ELSE '-' || $1.prerelease END ||
--         CASE WHEN $1.build IS NULL THEN '' ELSE '+' || $1.build END
-- 
-- $$ LANGUAGE SQL IMMUTABLE STRICT;
-- 
-- CREATE TYPE semver (
--     INPUT = semver_in,
--     OUTPUT = semver_out,
--     CATEGORY = 'S',
--     PREFERRED = false
-- );


SELECT has_type('semver'); 

SELECT lives_ok(
    format('SELECT semver(%L)', value), format('%L is a valid semver', value)
) FROM (VALUES
    (NULL),
    ('0.0.0'),
    ('1.2.3'),
    ('123.456.7890'),
    ('1.2.3-beta4'),
    ('1.2.3+abc'),
    ('1.2.3-beta4+abc')
) AS x(value);

SELECT throws_ok(
    format('SELECT semver(%L)', value), NULL, format('%L is not a valid semver', value)
) FROM (VALUES
    (''),
    ('b'),
    ('1.2'),
    ('1.2b'),
    ('1.2.3-'),
    ('1.2.3b'),
    ('1.2.3b#5'),
    ('v1.2.3')
) AS x(value);

SELECT collect_tap(ARRAY[
    ok(compare(semver(one), semver(two)) = 0, format('compare(semver(%L), semver(%L)) should = 0', one, two)),
    ok(compare(semver(two), semver(one)) = 0, format('compare(semver(%L), semver(%L)) should = 0', two, one)),
    ok(semver(one) = semver(two), format('semver(%L) should = semver(%L)', one, two)),
    ok(semver(two) = semver(one), format('semver(%L) should = semver(%L)', two, one))
]) FROM (VALUES
    ('1.2.3', '1.2.3'),
    ('0.1.2-beta3', '0.1.2-beta3'),
    ('1.0.0-rc-1', '1.0.0-RC-1'),
    ('4.5.6+abc', '4.5.6+xyz'),
    ('4.5.6-simba+abc', '4.5.6-simba+xyz')
) AS x(one, two);

SELECT collect_tap(ARRAY[
    ok(semver(less) < semver(more), format('semver(%L) should < semver(%L)', less, more)),
    ok(semver(more) > semver(less), format('semver(%L) should > semver(%L)', more, less))
]) FROM (VALUES
    ('1.0.0-alpha', '1.0.0-alpha.1'),
    ('1.0.0-alpha.1', '1.0.0-alpha.beta'),
    ('1.0.0-alpha.beta', '1.0.0-beta'),
    ('1.0.0-beta.2', '1.0.0-beta.11'),
    ('1.0.0-beta.11', '1.0.0-rc.1'),
    ('1.0.0-rc.1', '1.0.0')
) AS x(less, more);


SELECT * FROM finish();
ROLLBACK;
