BEGIN;

\i test/pgtap-core.sql
\i sql/semver.sql

SELECT * FROM no_plan();


SELECT collect_tap(ARRAY[
    ok(semver_compare(one, two) IS NULL, format('semver_compare(%s, %s) should be NULL', one, two)),
    ok(semver_compare(two, one) IS NULL, format('semver_compare(%s, %s) should be NULL', two, one))
]) FROM (VALUES
    ('1.2.3', NULL),
    ('1.2.3', ''),
    ('1.2.3', 'b'),
    ('1.2.3', '1.2'),
    ('1.2.3', '1.2b'),
    ('1.2.3', '1.2.3-'),
    ('1.2.3', '1.2.3b'),
    ('1.2.3', '1.2.3b#5'),
    ('1.2.3', 'v1.2.3')
) AS x(one, two);

SELECT collect_tap(ARRAY[
    ok(semver_compare(one, two) = 0, format('semver_compare(%s, %s) should = 0', one, two)),
    ok(semver_compare(two, one) = 0, format('semver_compare(%s, %s) should = 0', two, one))
]) FROM (VALUES
    ('1.2.3', '1.2.3'),
    ('0.1.2-beta3', '0.1.2-beta3'),
    ('1.0.0-rc-1', '1.0.0-RC-1'),
    ('4.5.6+abc', '4.5.6+xyz'),
    ('4.5.6-simba+abc', '4.5.6-simba+xyz')
) AS x(one, two);

SELECT collect_tap(ARRAY[
    ok(semver_compare(less, more) < 0, format('semver_compare(%s, %s) should < 0', less, more)),
    ok(semver_compare(more, less) > 0, format('semver_compare(%s, %s) should > 0', more, less))
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
