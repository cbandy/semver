-- vim: et:sw=4:ts=4

CREATE TYPE semver AS (
    version integer[],
    prerelease varchar COLLATE "C",
    build varchar COLLATE "C"
);

CREATE OR REPLACE FUNCTION semver(text)
RETURNS semver AS $$

    SELECT
        CASE
            WHEN array_length(version_array, 1) = 3
            THEN version_array::integer[]
            ELSE ARRAY[version]::integer[]
        END,
        prerelease,
        build
    FROM (
        SELECT
            string_to_array(regexp_matches[1], '.'),
            regexp_matches[1],
            regexp_matches[2],
            regexp_matches[3]
        FROM regexp_matches($1, '^(.*?)(?:-([[:alnum:].-]+))?(?:\+([[:alnum:].-]+))?$')
    ) parsed(version_array, version, prerelease, build)

$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION text(semver)
RETURNS text AS $$

    SELECT
        array_to_string($1.version, '.') ||
        CASE WHEN $1.prerelease IS NULL THEN '' ELSE '-' || $1.prerelease END ||
        CASE WHEN $1.build IS NULL THEN '' ELSE '+' || $1.build END

$$ LANGUAGE SQL IMMUTABLE STRICT;


-- CREATE CAST (text AS semver) WITH FUNCTION semver(text);
-- CREATE CAST (unknown AS semver) WITH FUNCTION semver(text);
-- CREATE CAST (record AS semver) WITH FUNCTION semver(text);


CREATE OR REPLACE FUNCTION compare(semver, semver)
RETURNS integer AS $$

    SELECT CASE
        WHEN $1.version < $2.version THEN -1
        WHEN $1.version > $2.version THEN 1
        ELSE CASE
            WHEN $1.prerelease IS NOT NULL AND $2.prerelease IS NULL THEN -1
            WHEN $1.prerelease IS NULL AND $2.prerelease IS NOT NULL THEN 1
            WHEN left_prerelease < right_prerelease THEN -1
            WHEN left_prerelease > right_prerelease THEN 1
            ELSE 0
        END
    END
    FROM (VALUES(
        (SELECT array_agg(CASE WHEN v ~ '^\d+$' THEN ROW(''::text, v::integer) ELSE ROW(v) END) FROM unnest(string_to_array(lower($1.prerelease), '.')) x(v)),
        (SELECT array_agg(CASE WHEN v ~ '^\d+$' THEN ROW(''::text, v::integer) ELSE ROW(v) END) FROM unnest(string_to_array(lower($2.prerelease), '.')) x(v))
    )) interpreted(left_prerelease, right_prerelease)

$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION equals(semver, semver)
RETURNS boolean AS 'SELECT compare($1, $2) = 0'
LANGUAGE SQL IMMUTABLE STRICT;

CREATE OPERATOR = (
    PROCEDURE = equals, LEFTARG = semver, RIGHTARG = semver,
    COMMUTATOR = =
);




CREATE OR REPLACE FUNCTION semver_compare(text, text)
RETURNS integer AS $$

    SELECT CASE
        WHEN left_version IS NULL OR right_version IS NULL THEN NULL
        WHEN array_length(left_version, 1) < 3 OR array_length(right_version, 1) < 3 THEN NULL
        WHEN left_version < right_version THEN -1
        WHEN left_version > right_version THEN 1
        ELSE CASE
            WHEN left_prerelease IS NOT NULL AND right_prerelease IS NULL THEN -1
            WHEN left_prerelease IS NULL AND right_prerelease IS NOT NULL THEN 1
            WHEN left_prerelease < right_prerelease THEN -1
            WHEN left_prerelease > right_prerelease THEN 1
            ELSE 0
        END
    END
    FROM (
        SELECT
            string_to_array(left_portions[1], '.')::integer[],
            string_to_array(right_portions[1], '.')::integer[],

            (SELECT array_agg(CASE WHEN v ~ '^\d+$' THEN ROW(''::text, v::integer) ELSE ROW(v) END) FROM unnest(string_to_array(lower(left_portions[2]), '.')) x (v)),
            (SELECT array_agg(CASE WHEN v ~ '^\d+$' THEN ROW(''::text, v::integer) ELSE ROW(v) END) FROM unnest(string_to_array(lower(right_portions[2]), '.')) x (v))
        FROM (VALUES (
            (SELECT * FROM regexp_matches($1, '^([[:digit:].]+)(?:-([[:alnum:].-]+))?(?:\+([[:alnum:].-]+))?$')),
            (SELECT * FROM regexp_matches($2, '^([[:digit:].]+)(?:-([[:alnum:].-]+))?(?:\+([[:alnum:].-]+))?$'))
        )) x (left_portions, right_portions)
    ) x (left_version, right_version, left_prerelease, right_prerelease)

$$ LANGUAGE SQL IMMUTABLE STRICT;
