-- test.sql --
select
    is_std('compress/flate.'), -- true
    is_std('compress/flate'), -- false
    is_std('foo/compress/flate.'); -- false
-- test.txt --
../testdata/testprog/go1.23.3.trace:
+---------------------------+--------------------------+-------------------------------+
| is_std('compress/flate.') | is_std('compress/flate') | is_std('foo/compress/flate.') |
+---------------------------+--------------------------+-------------------------------+
| true                      | false                    | false                         |
+---------------------------+--------------------------+-------------------------------+
