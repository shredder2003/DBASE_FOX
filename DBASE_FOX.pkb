create or replace package body dbase_fox as
  PREFIX     constant varchar2(32) default 'stage_';
  CR         constant varchar(2)   default chr(10); --preprocessor file requires only UNIX style
  MEMODTYPE  constant varchar2(32) default 'varchar2(4000)';
  ROWNUMNAME constant varchar2(32) default '"ROWNUM"';
  FRAMESIZE  constant integer      default 1000;

  addrownum      boolean := false;
  colnames       varchar2(255) := '';
  filename       varchar2(32)  := '';
  filename_noext varchar2(32)  := '';
  ext_tablename  varchar2(32)  := '';
  ext_table_filenames   varchar2(32000) := '';
  preprocessor_filename varchar2(32000) := '';
  dirpath        varchar2(32000) := '';
  dbfbfile       bfile := null;
  fptbfile       bfile := null;

  DBF_HEADER_SIZE constant number default 32;
  type dbf_header_type is record (
      version          varchar2(25) -- dBASE version number
     ,year             int          -- 1 byte int year, add to 1900
     ,month            int          -- 1 byte month
     ,day              int          -- 1 byte day
     ,no_records       int          -- number of records in file, 4 byte int
     ,hdr_len          int          -- length of header, 2 byte int
     ,rec_len          int          -- number of bytes in record, 2 byte int
     ,no_fields        int          -- number of fields
     ,lang_driver_id   int          -- language driver ID (codepage mark)
     ,lang_driver_name varchar2(20) -- codepage as oracle characterset
  );
  dbf_header dbf_header_type := null;
  subtype    dbf_header_data is raw(32);

  DBF_FIELD_DESCRIPTOR_SIZE constant number default 32;
  type dbf_field_descriptor_type is record (
      name     varchar2(11)
     ,type     char(1)
     ,length   int    -- 1 byte length
     ,decimals int    -- 1 byte scale
  );
  type dbf_field_descriptor_array is table of dbf_field_descriptor_type index by binary_integer;
  subtype dbf_field_descriptor_data is raw(32);
  dbf_field_descriptor dbf_field_descriptor_array;

  type rowarray_type is table of dbms_sql.varchar2_table index by binary_integer;
  rowarray rowarray_type;

  subtype raw_type is raw(4000);
  type rawarray_type is table of raw_type index by binary_integer;
  rawarray rawarray_type;

  loadcursor binary_integer;
  mblocksize number := 0;
  
  type lang_drivers_t is table of varchar2(100) index by pls_integer;
  lang_drivers lang_drivers_t;



  procedure get_header is
    l_data dbf_header_data;
  begin
    l_data := dbms_lob.substr(dbfbfile, DBF_HEADER_SIZE, 1);
    dbf_header.version          := utl_raw.cast_to_binary_integer(utl_raw.substr(l_data,  1, 1));
    dbf_header.year             := 1900 + utl_raw.cast_to_binary_integer(utl_raw.substr( l_data, 2, 1));
    dbf_header.month            := utl_raw.cast_to_binary_integer(utl_raw.substr(l_data,  3, 1));
    dbf_header.day              := utl_raw.cast_to_binary_integer(utl_raw.substr(l_data,  4, 1));
    dbf_header.no_records       := utl_raw.cast_to_binary_integer(utl_raw.substr(l_data,  5, 4),2);
    dbf_header.hdr_len          := utl_raw.cast_to_binary_integer(utl_raw.substr(l_data,  9, 2),2);
    dbf_header.rec_len          := utl_raw.cast_to_binary_integer(utl_raw.substr(l_data, 11, 2),2);
    dbf_header.lang_driver_id   := utl_raw.cast_to_binary_integer(utl_raw.substr(l_data, 30, 1));
    dbf_header.no_fields        := trunc((dbf_header.hdr_len - DBF_HEADER_SIZE) / DBF_FIELD_DESCRIPTOR_SIZE);
    if dbf_header.lang_driver_id>0 and lang_drivers.exists(dbf_header.lang_driver_id) then
        dbf_header.lang_driver_name := lang_drivers(dbf_header.lang_driver_id);
    else
        dbf_header.lang_driver_name := null;    
    end if;
  end;

  procedure get_header_fields is
    l_data dbf_field_descriptor_data;
  begin
    for i in 1 .. dbf_header.no_fields loop
      l_data := dbms_lob.substr(dbfbfile, DBF_FIELD_DESCRIPTOR_SIZE, 1+DBF_HEADER_SIZE+(i-1)*DBF_FIELD_DESCRIPTOR_SIZE); -- starting past the header
      dbf_field_descriptor(i).name     := rtrim(utl_raw.cast_to_varchar2(utl_raw.substr(l_data,1,11)),chr(0));
      dbf_field_descriptor(i).type     := utl_raw.cast_to_varchar2(utl_raw.substr(l_data, 12, 1));
      dbf_field_descriptor(i).length   := utl_raw.cast_to_binary_integer(utl_raw.substr(l_data, 17, 1));
      dbf_field_descriptor(i).decimals := utl_raw.cast_to_binary_integer(utl_raw.substr(l_data,18,1));
    end loop;
  end;

  procedure show_field_header_columns is
  begin
    dbms_output.put_line(CR||'Num'
               ||chr(9)||'Name       '
               ||chr(9)||'Type'
               ||chr(9)||'Length'
               ||chr(9)||'Decimals');
    dbms_output.put_line('==='
               ||chr(9)||'====       '
               ||chr(9)||'===='
               ||chr(9)||'======'
               ||chr(9)||'========');
  end;

  procedure show_header(p_file_length in integer) is
  begin
    dbms_output.put_line(chr(9)||dbf_header.version
                       ||chr(9)||dbf_header.year
                       ||chr(9)||dbf_header.month
                       ||chr(9)||dbf_header.day
                       ||chr(9)||dbf_header.no_records
                       ||chr(9)||dbf_header.hdr_len
                       ||chr(9)||dbf_header.rec_len
                       ||chr(9)||dbf_header.no_fields
                       ||chr(9)||p_file_length
                       ||chr(9)||dbf_header.lang_driver_id||case when dbf_header.lang_driver_name is not null then ' ('||dbf_header.lang_driver_name||')' end
                       );
  end;

  procedure show_fields is
      l_record_length number := 0;
  begin
    for i in dbf_field_descriptor.first .. dbf_field_descriptor.last loop
      dbms_output.put_line(i
                 ||chr(9)||rpad(dbf_field_descriptor(i).name,11,' ')
                 ||chr(9)||dbf_field_descriptor(i).type
                 ||chr(9)||dbf_field_descriptor(i).length
                 ||chr(9)||dbf_field_descriptor(i).decimals);
        l_record_length := l_record_length + dbf_field_descriptor(i).length;
    end loop;
    dbms_output.put_line('control record length: '||l_record_length);
  end;

  function build_insert return varchar2 is
    l_statement long;
  begin
    l_statement := 'insert into ' || PREFIX || filename_noext || ' (';

    if colnames is not null then
      l_statement := l_statement || colnames;
    else
      for i in dbf_field_descriptor.first .. dbf_field_descriptor.last loop
        if i <> 1 then
          l_statement := l_statement || ',';
        end if;
        l_statement := l_statement || '"'||  dbf_field_descriptor(i).name || '"';
      end loop;
      if addrownum then
        l_statement := l_statement || ',' || ROWNUMNAME;
      end if;
    end if;

    l_statement := l_statement || ') values (';

    for i in dbf_field_descriptor.first .. dbf_field_descriptor.last loop
      if i <> 1 then
        l_statement := l_statement || ',';
      end if;
      if dbf_field_descriptor(i).type = 'D' then
        l_statement := l_statement || 'to_date(:bv' || i || ',''yyyymmdd'' )';
      else
        l_statement := l_statement || ':bv' || i;
      end if;
    end loop;
    if addrownum then
      l_statement := l_statement || ',:bv' || (dbf_field_descriptor.last + 1);
    end if;
    l_statement := l_statement || ')';
    return l_statement;
  end;

  function build_create return varchar2 is
    l_statement long;
  begin
    l_statement := 'create table ' || PREFIX || filename_noext || ' (';

    for i in dbf_field_descriptor.first .. dbf_field_descriptor.last loop
      l_statement := l_statement || CR;
      if i <> dbf_field_descriptor.first then
        l_statement := l_statement ||',';
      else
        l_statement := l_statement ||' ';
      end if;
      l_statement := l_statement || '"'||  dbf_field_descriptor(i).name || '"'||chr(9);
      if dbf_field_descriptor(i).type = 'D' then
        l_statement := l_statement || 'date';
      elsif dbf_field_descriptor(i).type = 'F' then
        l_statement := l_statement || 'float';
      elsif dbf_field_descriptor(i).type = 'N' then
        if dbf_field_descriptor(i).decimals > 0 then
          l_statement := l_statement || 'number('||dbf_field_descriptor(i).length||','|| dbf_field_descriptor(i).decimals || ')';
        else
          l_statement := l_statement || 'number('||dbf_field_descriptor(i).length||')';
        end if;
      elsif dbf_field_descriptor(i).type = 'M' then
        l_statement := l_statement || MEMODTYPE;
      else
        l_statement := l_statement || 'varchar2(' || dbf_field_descriptor(i).length || ')';
      end if;
    end loop;
    if addrownum then
      l_statement := l_statement || CR || ',' || ROWNUMNAME || chr(9) || 'number';
    end if;
    l_statement := l_statement ||CR||');'||CR||'/';
    return l_statement;
  end;

  
  function build_preprocessor return varchar2 is
    v_result varchar2(32000);
  begin
      v_result := '#!/bin/sh'||CR||
                  '/usr/bin/tail -c +'||(dbf_header.hdr_len+1)||' $1 | /usr/bin/head -c -1'||CR;
      return v_result;            
  end build_preprocessor;

  procedure save_preprocessor(v_text varchar2) is
      l_output utl_file.file_type;
  begin
      l_output := utl_file.fopen( DBF_FILES_DIRECTORY, preprocessor_filename, 'w', 32767 );
      utl_file.put( l_output, v_text );
      utl_file.fclose( l_output );
  end;


  function build_create_external return varchar2 is
    l_statement long;
    l_record_structure long := '';
  begin
    l_statement := 'create table ' || ext_tablename || ' (';

    for i in dbf_field_descriptor.first .. dbf_field_descriptor.last loop
      l_statement := l_statement || CR;
      l_record_structure := l_record_structure || CR;
      if i <> dbf_field_descriptor.first then
        l_statement := l_statement ||',';
        l_record_structure := l_record_structure ||',';
      else
        l_statement := l_statement ||' DELETE_FLAG VARCHAR2(1), '|| CR;
        l_record_structure := l_record_structure ||' DELETE_FLAG CHAR(1), '|| CR;
      end if;
      l_statement := l_statement || '"'||  dbf_field_descriptor(i).name || '"'||chr(9);
      l_record_structure := l_record_structure || '"'||  dbf_field_descriptor(i).name || '"'||chr(9);
      if dbf_field_descriptor(i).type = 'D' then
        l_statement := l_statement || 'date';
        l_record_structure := l_record_structure ||'CHAR('||dbf_field_descriptor(i).length||') date_format DATE mask "yyyymmdd"';
      elsif dbf_field_descriptor(i).type = 'F' then
        l_statement := l_statement || 'float';
        l_record_structure := l_record_structure ||'FLOAT EXTERNAL('||dbf_field_descriptor(i).length||')';
      elsif dbf_field_descriptor(i).type = 'N' then
        if dbf_field_descriptor(i).decimals > 0 then
          l_statement := l_statement || 'number('||dbf_field_descriptor(i).length||','|| dbf_field_descriptor(i).decimals || ')';
        else
          l_statement := l_statement || 'number('||dbf_field_descriptor(i).length||')';
        end if;
        l_record_structure := l_record_structure ||'INTEGER EXTERNAL('||dbf_field_descriptor(i).length||')';
      elsif dbf_field_descriptor(i).type = 'M' then
        l_statement := l_statement || MEMODTYPE;
      else
        l_statement := l_statement || 'varchar2(' || dbf_field_descriptor(i).length || ')';
        l_record_structure := l_record_structure ||'CHAR('||dbf_field_descriptor(i).length||')';
      end if;
    end loop;
    if addrownum then
      l_statement := l_statement || CR || ',' || ROWNUMNAME || chr(9) || 'number';
    end if;
    l_statement := l_statement ||CR||')
        ORGANIZATION external
        (
          TYPE oracle_loader
          DEFAULT DIRECTORY '||DBF_FILES_DIRECTORY||'
          ACCESS PARAMETERS
          (
            RECORDS FIXED '||dbf_header.rec_len||'
            PREPROCESSOR '''||preprocessor_filename||'''
            '
          ||case when dbf_header.lang_driver_name is not null then 'CHARACTERSET '||dbf_header.lang_driver_name end||'
            STRING SIZES ARE IN BYTES
            NOBADFILE
            NOLOGFILE
            READSIZE 1048576
            FIELDS
                ('||l_record_structure||'
                )
          )
          location('''||replace(nvl(ext_table_filenames,filename),',',''',''')||''')
        )REJECT LIMIT 0';
    return l_statement;
  end build_create_external;


  procedure show_header_columns is
  begin
    dbms_output.put_line(
             CR||'DBASE File'
               ||chr(9)||'Version'
               ||chr(9)||'Year'
               ||chr(9)||'Month'
               ||chr(9)||'Day'
               ||chr(9)||'#Recs'
               ||chr(9)||'HdrLen'
               ||chr(9)||'RecLen'
               ||chr(9)||'#Fields'
               ||chr(9)||'Size'
               ||chr(9)||'CodePage'
               );
    dbms_output.put_line(
                         '============'
               ||chr(9)||'======='
               ||chr(9)||'===='
               ||chr(9)||'====='
               ||chr(9)||'==='
               ||chr(9)||'====='
               ||chr(9)||'======'
               ||chr(9)||'======'
               ||chr(9)||'======='
               ||chr(9)||'===='
               ||chr(9)||'========'
               );
  end;

  procedure loadtablerecord(i in number) is
    l_n      number;
    l_fblock number;
    l_data   raw_type;
  begin
    l_data := dbms_lob.substr(dbfbfile,dbf_header.rec_len,2+DBF_HEADER_SIZE+dbf_header.no_fields*DBF_FIELD_DESCRIPTOR_SIZE+(i-1)*dbf_header.rec_len); -- starting past the header and field descriptors
    rawarray(0) := utl_raw.substr(l_data, 1, 1);
    l_n := 2;
    for j in 1 .. dbf_header.no_fields loop
      rawarray(j) := utl_raw.substr(l_data,l_n,dbf_field_descriptor(j).length);
      if dbf_field_descriptor(j).type = 'F' and rawarray(j) = '.' then
        rawarray(j) := null;
      elsif dbf_field_descriptor(j).type = 'M' then
        if dbms_lob.isopen(fptbfile) != 0 then
          l_fblock := nvl(utl_raw.cast_to_binary_integer(dbms_lob.substr(fptbfile, 4, to_number(trim(utl_raw.cast_to_varchar2(rawarray(j))))*mblocksize+5)),0);
          rawarray(j) := dbms_lob.substr(fptbfile, l_fblock, to_number(trim(utl_raw.cast_to_varchar2(rawarray(j))))*mblocksize+9);
        else
          dbms_output.put_line(filename || '.fpt not found');
        end if;
      end if;
      l_n := l_n + dbf_field_descriptor(j).length;
    end loop;
  end;
  
  procedure loadtablearray(p_cntarr in int) is
    l_bulkcnt number;
  begin
    for j in 1 .. dbf_header.no_fields loop
      dbms_sql.bind_array(loadcursor, ':bv'||j, rowarray(j),1,p_cntarr);
    end loop;
    if addrownum then
      dbms_sql.bind_array(loadcursor, ':bv'||(dbf_header.no_fields+1), rowarray(dbf_header.no_fields+1),1,p_cntarr);
    end if;
    begin
      l_bulkcnt := dbms_sql.execute(loadcursor);
      --dbms_output.put_line('Bulk insert count ' || l_bulkcnt);
    exception
      when others then
        dbms_output.put_line('Bulk insert failed ' || sqlerrm);
        dbms_output.put_line(build_insert);
    end;
  end;

  procedure loadtablebulk is
    l_cntrow int default 0;
    l_cntarr int default 0;
  begin
    loadcursor := dbms_sql.open_cursor;
    dbms_sql.parse(loadcursor, build_insert, dbms_sql.native);

    for i in 1 .. dbf_header.no_records loop
      loadtablerecord(i);
      if utl_raw.cast_to_varchar2(rawarray(0)) <> '*' then
        l_cntarr := l_cntarr + 1;
        for j in 1 .. dbf_header.no_fields loop
          rowarray(j)(l_cntarr) := trim(utl_raw.cast_to_varchar2(rawarray(j)));
        end loop;
        if addrownum then
          l_cntrow := l_cntrow + 1;
          rowarray((dbf_header.no_fields+1))(l_cntarr) := l_cntrow;
        end if;
        if l_cntarr >= FRAMESIZE then
          loadtablearray(l_cntarr);
          l_cntarr := 0;
        end if;
      end if;
    end loop;
    if l_cntarr > 0 then
      loadtablearray(l_cntarr);
    end if;

    dbms_sql.close_cursor(loadcursor);
  exception
    when others then
      if dbms_sql.is_open(loadcursor) then
        dbms_sql.close_cursor(loadcursor);
      end if;
      dbms_output.put_line('loadtable failed for ' || filename);
      dbms_output.put_line('insert ' || build_insert);
  end;

  procedure open_dbf is
  begin
    dbms_output.put_line('file: ' || DBF_FILES_DIRECTORY||'/'||filename);
    dbfbfile := bfilename(DBF_FILES_DIRECTORY, filename/* || '.dbf'*/); --coz russian FIAS filename extensions in uppercase
    dbms_lob.fileopen(dbfbfile);
  end;

  procedure open_fpt is
  begin
    fptbfile := bfilename(DBF_FILES_DIRECTORY, filename || '.fpt');
    if dbms_lob.fileexists(fptbfile) != 0 then
      dbms_lob.fileopen(fptbfile);
    end if;
  end;

  procedure close_dbf is
  begin
    if dbms_lob.isopen(dbfbfile) > 0 then
      dbms_lob.fileclose(dbfbfile);
    end if;
  end;

  procedure close_fpt is
  begin
    if dbms_lob.isopen(fptbfile) > 0 then
      dbms_lob.fileclose(fptbfile);
    end if;
  end;


  procedure init_lang_drivers is
  begin
    /*
    
        select *
        from V$NLS_VALID_VALUES
        where parameter = 'CHARACTERSET'
        and value like '%07%'
        ;
    
    */
      lang_drivers(TO_NUMBER('00', 'xx')) := null; --No codepage defined
      lang_drivers(TO_NUMBER('01', 'xx')) := 'US8PC437'; --Codepage 437 (US MS-DOS)
      lang_drivers(TO_NUMBER('02', 'xx')) := 'WE8PC850'; --Codepage 850 (International MS-DOS)
      lang_drivers(TO_NUMBER('03', 'xx')) := 'WE8MSWIN1252'; --Codepage 1252 Windows ANSI
      lang_drivers(TO_NUMBER('04', 'xx')) := null; --Codepage 10000 Standard MacIntosh
      lang_drivers(TO_NUMBER('64', 'xx')) := 'EE8PC852'; --Codepage 852 Easern European MS-DOS
      lang_drivers(TO_NUMBER('65', 'xx')) := 'RU8PC866'; --Codepage 866 Russian MS-DOS
      lang_drivers(TO_NUMBER('66', 'xx')) := 'N8PC865'; --Codepage 865 Nordic MS-DOS
      lang_drivers(TO_NUMBER('67', 'xx')) := 'IS8PC861'; --Codepage 861 Icelandic MS-DOS
      lang_drivers(TO_NUMBER('68', 'xx')) := null; --Codepage 895 Kamenicky (Czech) MS-DOS
      lang_drivers(TO_NUMBER('69', 'xx')) := null; --Codepage 620 Mazovia (Polish) MS-DOS
      lang_drivers(TO_NUMBER('6A', 'xx')) := 'EL8PC737'; --Codepage 737 Greek MS-DOS (437G)
      lang_drivers(TO_NUMBER('6B', 'xx')) := 'TR8PC857'; --Codepage 857 Turkish MS-DOS
      lang_drivers(TO_NUMBER('78', 'xx')) := null; --Codepage 950 Chinese (Hong Kong SAR, Taiwan) Windows
      lang_drivers(TO_NUMBER('79', 'xx')) := 'KO16MSWIN949'; --Codepage 949 Korean Windows
      lang_drivers(TO_NUMBER('7A', 'xx')) := null; --Codepage 936 Chinese (PRC, Singapore) Windows
      lang_drivers(TO_NUMBER('7B', 'xx')) := null; --Codepage 932 Japanese Windows
      lang_drivers(TO_NUMBER('7C', 'xx')) := null; --Codepage 874 Thai Windows
      lang_drivers(TO_NUMBER('7D', 'xx')) := 'IW8MSWIN1255'; --Codepage 1255 Hebrew Windows
      lang_drivers(TO_NUMBER('7E', 'xx')) := 'AR8MSWIN1256'; --Codepage 1256 Arabic Windows
      lang_drivers(TO_NUMBER('96', 'xx')) := null; --Codepage 10007 Russian MacIntosh
      lang_drivers(TO_NUMBER('97', 'xx')) := null; --Codepage 10029 MacIntosh EE
      lang_drivers(TO_NUMBER('98', 'xx')) := null; --Codepage 10006 Greek MacIntosh
      lang_drivers(TO_NUMBER('C8', 'xx')) := 'EE8MSWIN1250'; --Codepage 1250 Eastern European Windows
      lang_drivers(TO_NUMBER('C9', 'xx')) := 'CL8MSWIN1251'; --Codepage 1251 Russian Windows
      lang_drivers(TO_NUMBER('CA', 'xx')) := 'TR8MSWIN1254'; --Codepage 1254 Turkish Windows
      lang_drivers(TO_NUMBER('CB', 'xx')) := 'EL8MSWIN1253'; --Codepage 1253 Greek Windows
  end init_lang_drivers;

  procedure initialize is
    l_empty_dbf_field_descriptor dbf_field_descriptor_array;
    l_empty_rowarray rowarray_type;
    l_empty_rawarray rawarray_type;
  begin
    dbfbfile := null;
    fptbfile := null;
    dbf_field_descriptor := l_empty_dbf_field_descriptor;
    dbf_header := null;
    rowarray := l_empty_rowarray;
    rawarray := l_empty_rawarray;
    loadcursor := 0;
    mblocksize := 0;
    init_lang_drivers;
    filename_noext := nvl(substr(filename,1,instr(filename,'.',-1)-1),filename);
    preprocessor_filename := 'dbf_to_flat_preprocessor_'||filename_noext||'.sh';
    ext_tablename := PREFIX || filename_noext || '_ext';
    begin
        select DIRECTORY_PATH
        into dirpath
        from all_directories
        where DIRECTORY_NAME = DBF_FILES_DIRECTORY
        ;
    exception when others then
        raise_application_error(-20003,'There is no directory '||DBF_FILES_DIRECTORY||' in all_directories !');
    end; 
  end initialize;

  /* 
     1. creates preprocessor file to convert dbf to flat
     2. creates table organization external with preprocessor
  */
  procedure createExternalTable(
                      p_filename in varchar2
                     --,p_colnames in varchar2 default null
                     --,p_rownum in boolean default false
                     ,p_ext_table_filenames in varchar2 default null --external table location filenames, comma delimited
                     ) is
      v_preprocessor  varchar2(32767);
      v_ext_table_ddl varchar2(32767);
      v_dummy         varchar2(32767);
      v_sql           varchar2(32767);
  begin
    filename := p_filename;
    ext_table_filenames := p_ext_table_filenames;
    addrownum := false; --p_rownum;
    colnames := null; --p_colnames;

    initialize;

    open_dbf;

    get_header;
    get_header_fields;

    show_header_columns;
    dbms_output.put(filename/* || '.dbf'*/);
    show_header(dbms_lob.getlength(dbfbfile));
    
    dbms_output.put_line(CR||'Preprocessor:');
    v_preprocessor := build_preprocessor;
    dbms_output.put_line(v_preprocessor);
      
    dbms_output.put_line(CR||'Create table organization EXTERNAL statement:');
    v_ext_table_ddl := build_create_external;
    dbms_output.put_line(CR||v_ext_table_ddl||';');

    dbms_output.put_line(CR||'Save preprocessor to file '||preprocessor_filename||'...');
    save_preprocessor(v_preprocessor);
    dbms_output.put_line('OK');
    
    dbms_output.put_line(CR||'Creating external table '||ext_tablename||'... ');
    begin
        execute immediate 'drop table '||ext_tablename;
    exception when others then null;
    end;
    execute immediate v_ext_table_ddl;
    dbms_output.put_line('OK');

    dbms_output.put_line(CR||'Selecting from external table '||ext_tablename||'... ');
    v_sql := '
    select delete_flag
    from '||ext_tablename||'
    where rownum = 1 ';
    begin
        execute immediate v_sql into v_dummy;
        dbms_output.put_line('OK');
    exception when others then
        if sqlerrm like '%error during exec%' then
            dbms_output.put_line('YOU HAVE TO MANUALLY SET EXEC PERMISSION TO FILE USING THIS COMMAND IN UNIX:');
            dbms_output.put_line('chmod u+x '||dirpath||'/'||preprocessor_filename);
        end if;
        dbms_output.put_line('Error: '||sqlerrm);
    end;    
    
    close_dbf;
  /*exception
    when others then
      close_dbf;
      raise;*/
  end createExternalTable;


  procedure showtable(p_filename in varchar2
                     ,p_colnames in varchar2 default null
                     ,p_rownum in boolean default false
                     ,p_ext_table_filenames in varchar2 default null --external table location filenames, comma delimited
                     ) is
  begin
    filename := p_filename;
    ext_table_filenames := p_ext_table_filenames;
    addrownum := p_rownum;
    colnames := p_colnames;

    initialize;

    open_dbf;

    get_header;
    get_header_fields;

    show_header_columns;
    dbms_output.put(filename/* || '.dbf'*/);
    show_header(dbms_lob.getlength(dbfbfile));
    show_field_header_columns;
    show_fields;

    dbms_output.put_line(CR||'Insert statement:');
    dbms_output.put_line(build_insert);

    dbms_output.put_line(CR||'Create statement:');
    dbms_output.put_line(build_create);

    dbms_output.put_line(CR||'Create EXTERNAL statement:');
    dbms_output.put_line(build_create_external);

    close_dbf;
  exception
    when others then
      close_dbf;
      raise;
  end;

  procedure loadtable(p_filename in varchar2, p_colnames in varchar2 default null, p_rownum in boolean default false) is
  begin
    filename := p_filename;
    addrownum := p_rownum;
    colnames := p_colnames;

    initialize;

    open_dbf;
    open_fpt;

    if dbms_lob.isopen(fptbfile) > 0 then
      mblocksize := utl_raw.cast_to_binary_integer(dbms_lob.substr(fptbfile, 2, 7));
    else
      mblocksize := 0;
    end if;

    get_header;
    get_header_fields;

    loadtablebulk;

    close_dbf;
    close_fpt;
  exception
    when others then
      close_dbf;
      close_fpt;
      raise;
  end;

end;
/


declare
begin
  dbase_fox.showtable('names');
  dbase_fox.showtable('comps');
  dbase_fox.showtable('locs');
  dbase_fox.showtable('jobs');
  dbase_fox.showtable('orders', p_rownum=>true);

  dbase_fox.loadtable('names');
  dbase_fox.loadtable('comps');
  dbase_fox.loadtable('locs');
  dbase_fox.loadtable('jobs');
  dbase_fox.loadtable('orders', p_rownum=>true);
end;
/

create directory DBF_FILES as '/u01/oracle/oebs/apps/apps_st/comn/temp';


DECLARE
BEGIN
--dbase_fox.DBF_FILES_DIRECTORY := 'DBF_FILES';
--dbase_fox.showtable('ADDROB01.DBF');
dbase_fox.createExternalTable('ADDROB01.DBF','ADDROB01.DBF,ADDROB02.DBF');
END;
/

BEGIN
  dbms_scheduler.create_job(job_name        => 'myjob',
                            job_type        => 'executable',
                            job_action      => '/bin/chmod',
                            number_of_arguments => 2,
                            enabled         => FALSE,
                            auto_drop       => false);
  dbms_scheduler.set_job_argument_value('myjob', 1, 'o+x');
  dbms_scheduler.set_job_argument_value('myjob', 2, '/u01/oracle/oebs/apps/apps_st/comn/temp/dbf_to_flat_preprocessor_ADDROB01.sh');
  DBMS_SCHEDULER.SET_ATTRIBUTE('myjob','logging_level',DBMS_SCHEDULER.LOGGING_FULL);
  dbms_scheduler.enable('myjob');
END;
/

begin
  dbms_scheduler.enable('myjob');
--dbms_scheduler.run_job('myjob');
--dbms_scheduler.drop_job('myjob');
end;
/

select *
from dba_scheduler_job_log
where job_name = 'myjob'
--and owner = 'XXFIN'
;

select *
from ALL_SCHEDULER_JOB_RUN_DETAILS
;