create or replace package dbase_fox as

  DBF_FILES_DIRECTORY VARCHAR2(32) := 'DBF_FILES';

  -- procedure to a load a table with records
  -- from a DBASE file.
  --
  -- Uses a BFILE to read binary data and dbms_sql
  -- to dynamically insert into any table you
  -- have insert on.
  --
  -- p_filename is the name of a file in that directory
  --            will be the name of the DBASE file
  -- p_colnames is an optional list of comma separated
  --            column names.  If not supplied, this pkg
  --            assumes the column names in the DBASE file
  --            are the same as the column names in the
  --            table
  -- p_rownum boolean that activates an autonum
  --          functionality such that a sequential
  --          numbered virtual column is created
  procedure loadtable(p_filename in varchar2
                    , p_colnames in varchar2 default null
                    , p_rownum in boolean default false
                     );

  /*
  procedure to print (and not insert) what we find in
  the DBASE files (not the data, just the info
  from the dbase headers....)
  
  p_filename is the name of a file in that directory
             will be the name of the DBASE file
  p_colnames is an optional list of comma separated
             column names.  If not supplied, this pkg
             assumes the column names in the DBASE file
             are the same as the column names in the
             table
  p_rownum boolean that activates an autonum
           functionality such that a sequential
           numbered virtual column is created
  p_ext_table_filenames is an optional list of comma separated file names,
                        for creating external table over more than 1 file
                        i.e. 'large_table_part1.dbf,large_table_part2.dbf'
  */
  procedure showtable(p_filename in varchar2
                    , p_colnames in varchar2 default null
                    , p_rownum in boolean default false
                    , p_ext_table_filenames in varchar2 default null --external table location filenames, comma delimited
                     );

  /* 
  procedure to create and test external table over dbf file.
   1. creates preprocessor file to convert dbf to flat
   2. creates table organization external with preprocessor
  
  p_filename is the name of a file in that directory
             will be the name of the DBASE file
  p_ext_table_filenames is an optional list of comma separated file names,
                        for creating external table over more than 1 file
                        i.e. 'large_table_part1.dbf,large_table_part2.dbf'
  */
  procedure createExternalTable(
                      p_filename in varchar2
                     ,p_ext_table_filenames in varchar2 default null --external table location filenames, comma delimited
                     );


end;
/
