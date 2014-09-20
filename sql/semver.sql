-- vim: et:sw=4:ts=4

CREATE OR REPLACE FUNCTION semver_compare(text, text)
RETURNS integer AS $$

    WITH
    portion ("left", "right") AS (
        VALUES (
            (SELECT * FROM regexp_matches($1, '^([[:digit:].]+)(?:-([[:alnum:].-]+))?(?:\+([[:alnum:].-]+))?$')),
            (SELECT * FROM regexp_matches($2, '^([[:digit:].]+)(?:-([[:alnum:].-]+))?(?:\+([[:alnum:].-]+))?$'))
        )
    ),
    version ("left", "right") AS (
        SELECT
            string_to_array(portion.left[1], '.')::integer[],
            string_to_array(portion.right[1], '.')::integer[]
        FROM portion
    ),
    prerelease ("left", "right") AS (
        SELECT
            (SELECT array_agg(CASE WHEN v ~ '^\d+$' THEN ROW(''::text, v::integer) ELSE ROW(v) END) FROM unnest(string_to_array(lower(portion.left[2]), '.')) x (v)),
            (SELECT array_agg(CASE WHEN v ~ '^\d+$' THEN ROW(''::text, v::integer) ELSE ROW(v) END) FROM unnest(string_to_array(lower(portion.right[2]), '.')) x (v))
        FROM portion
    )
    SELECT CASE
        WHEN version.left IS NULL OR version.right IS NULL THEN NULL
        WHEN array_length(version.left, 1) < 3 OR array_length(version.right, 1) < 3 THEN NULL
        WHEN version.left < version.right THEN -1
        WHEN version.left > version.right THEN 1
        ELSE CASE
            WHEN prerelease.left IS NOT NULL AND prerelease.right IS NULL THEN -1
            WHEN prerelease.left IS NULL AND prerelease.right IS NOT NULL THEN 1
            WHEN prerelease.left < prerelease.right THEN -1
            WHEN prerelease.left > prerelease.right THEN 1
            ELSE 0
        END
    END
    FROM version, prerelease

$$ LANGUAGE SQL IMMUTABLE STRICT;
