
oracle pl\sql package DBASE_PKG from Tom Kyte, improved:
1. loading using SqlLoader engine, not ps\sql engine. It have to be much faster.
2. external table over .dbf file (without creating real table and import to it) more useful, especially for large .dbf files.
3. .dbf codepage takes into consideration.



#examples of using

##show .dbf structure

###command
```sql
create directory DBF_FILES as '/tmp';

BEGIN
    --show .dbf structure
    dbase_fox.showtable('ADDROB01.DBF');
END;
/
```

###output

```sql
file: DBF_FILES/ADDROB01.DBF

DBASE File	Version	Year	Month	Day	#Recs	HdrLen	RecLen	#Fields	Size	CodePage
============	=======	====	=====	===	=====	======	======	=======	====	========
ADDROB01.DBF	3	2049	1	1	20082	1281	710	39	14259502	101 (RU8PC866)

Num	Name       	Type	Length	Decimals
===	====       	====	======	========
1	ACTSTATUS  	N	2	0
2	AOGUID     	C	36	0
3	AOID       	C	36	0
4	AOLEVEL    	N	2	0
5	AREACODE   	C	3	0
6	AUTOCODE   	C	1	0
7	CENTSTATUS 	N	2	0
8	CITYCODE   	C	3	0
9	CODE       	C	17	0
10	CURRSTATUS 	N	2	0
11	ENDDATE    	D	8	0
12	FORMALNAME 	C	120	0
13	IFNSFL     	C	4	0
14	IFNSUL     	C	4	0
15	NEXTID     	C	36	0
16	OFFNAME    	C	120	0
17	OKATO      	C	11	0
18	OKTMO      	C	11	0
19	OPERSTATUS 	N	2	0
20	PARENTGUID 	C	36	0
21	PLACECODE  	C	3	0
22	PLAINCODE  	C	15	0
23	POSTALCODE 	C	6	0
24	PREVID     	C	36	0
25	REGIONCODE 	C	2	0
26	SHORTNAME  	C	10	0
27	STARTDATE  	D	8	0
28	STREETCODE 	C	4	0
29	TERRIFNSFL 	C	4	0
30	TERRIFNSUL 	C	4	0
31	UPDATEDATE 	D	8	0
32	CTARCODE   	C	3	0
33	EXTRCODE   	C	4	0
34	SEXTCODE   	C	3	0
35	LIVESTATUS 	N	2	0
36	NORMDOC    	C	36	0
37	PLANCODE   	C	4	0
38	CADNUM     	C	100	0
39	DIVTYPE    	N	1	0
control record length: 709

Insert statement:
insert into stage_ADDROB01 ("ACTSTATUS","AOGUID","AOID","AOLEVEL","AREACODE","AUTOCODE","CENTSTATUS","CITYCODE","CODE","CURRSTATUS","ENDDATE","FORMALNAME","IFNSFL","IFNSUL","NEXTID","OFFNAME","OKATO","OKTMO","OPERSTATUS","PARENTGUID","PLACECODE","PLAINCODE","POSTALCODE","PREVID","REGIONCODE","SHORTNAME","STARTDATE","STREETCODE","TERRIFNSFL","TERRIFNSUL","UPDATEDATE","CTARCODE","EXTRCODE","SEXTCODE","LIVESTATUS","NORMDOC","PLANCODE","CADNUM","DIVTYPE") values (:bv1,:bv2,:bv3,:bv4,:bv5,:bv6,:bv7,:bv8,:bv9,:bv10,to_date(:bv11,'yyyymmdd' ),:bv12,:bv13,:bv14,:bv15,:bv16,:bv17,:bv18,:bv19,:bv20,:bv21,:bv22,:bv23,:bv24,:bv25,:bv26,to_date(:bv27,'yyyymmdd' ),:bv28,:bv29,:bv30,to_date(:bv31,'yyyymmdd' ),:bv32,:bv33,:bv34,:bv35,:bv36,:bv37,:bv38,:bv39)

Create statement:
create table stage_ADDROB01 (
 "ACTSTATUS"	number(2)
,"AOGUID"	varchar2(36)
,"AOID"	varchar2(36)
,"AOLEVEL"	number(2)
,"AREACODE"	varchar2(3)
,"AUTOCODE"	varchar2(1)
,"CENTSTATUS"	number(2)
,"CITYCODE"	varchar2(3)
,"CODE"	varchar2(17)
,"CURRSTATUS"	number(2)
,"ENDDATE"	date
,"FORMALNAME"	varchar2(120)
,"IFNSFL"	varchar2(4)
,"IFNSUL"	varchar2(4)
,"NEXTID"	varchar2(36)
,"OFFNAME"	varchar2(120)
,"OKATO"	varchar2(11)
,"OKTMO"	varchar2(11)
,"OPERSTATUS"	number(2)
,"PARENTGUID"	varchar2(36)
,"PLACECODE"	varchar2(3)
,"PLAINCODE"	varchar2(15)
,"POSTALCODE"	varchar2(6)
,"PREVID"	varchar2(36)
,"REGIONCODE"	varchar2(2)
,"SHORTNAME"	varchar2(10)
,"STARTDATE"	date
,"STREETCODE"	varchar2(4)
,"TERRIFNSFL"	varchar2(4)
,"TERRIFNSUL"	varchar2(4)
,"UPDATEDATE"	date
,"CTARCODE"	varchar2(3)
,"EXTRCODE"	varchar2(4)
,"SEXTCODE"	varchar2(3)
,"LIVESTATUS"	number(2)
,"NORMDOC"	varchar2(36)
,"PLANCODE"	varchar2(4)
,"CADNUM"	varchar2(100)
,"DIVTYPE"	number(1)
);
/

Create EXTERNAL statement:
create table stage_ADDROB01_ext (
 DELETE_FLAG VARCHAR2(1), 
"ACTSTATUS"	number(2)
,"AOGUID"	varchar2(36)
,"AOID"	varchar2(36)
,"AOLEVEL"	number(2)
,"AREACODE"	varchar2(3)
,"AUTOCODE"	varchar2(1)
,"CENTSTATUS"	number(2)
,"CITYCODE"	varchar2(3)
,"CODE"	varchar2(17)
,"CURRSTATUS"	number(2)
,"ENDDATE"	date
,"FORMALNAME"	varchar2(120)
,"IFNSFL"	varchar2(4)
,"IFNSUL"	varchar2(4)
,"NEXTID"	varchar2(36)
,"OFFNAME"	varchar2(120)
,"OKATO"	varchar2(11)
,"OKTMO"	varchar2(11)
,"OPERSTATUS"	number(2)
,"PARENTGUID"	varchar2(36)
,"PLACECODE"	varchar2(3)
,"PLAINCODE"	varchar2(15)
,"POSTALCODE"	varchar2(6)
,"PREVID"	varchar2(36)
,"REGIONCODE"	varchar2(2)
,"SHORTNAME"	varchar2(10)
,"STARTDATE"	date
,"STREETCODE"	varchar2(4)
,"TERRIFNSFL"	varchar2(4)
,"TERRIFNSUL"	varchar2(4)
,"UPDATEDATE"	date
,"CTARCODE"	varchar2(3)
,"EXTRCODE"	varchar2(4)
,"SEXTCODE"	varchar2(3)
,"LIVESTATUS"	number(2)
,"NORMDOC"	varchar2(36)
,"PLANCODE"	varchar2(4)
,"CADNUM"	varchar2(100)
,"DIVTYPE"	number(1)
)
        ORGANIZATION external
        (
          TYPE oracle_loader
          DEFAULT DIRECTORY DBF_FILES
          ACCESS PARAMETERS
          (
            RECORDS FIXED 710
            PREPROCESSOR 'dbf_to_flat_preprocessor_ADDROB01.sh'
            CHARACTERSET RU8PC866
            STRING SIZES ARE IN BYTES
            NOBADFILE
            NOLOGFILE
            READSIZE 1048576
            FIELDS
                (
 DELETE_FLAG CHAR(1), 
"ACTSTATUS"	INTEGER EXTERNAL(2)
,"AOGUID"	CHAR(36)
,"AOID"	CHAR(36)
,"AOLEVEL"	INTEGER EXTERNAL(2)
,"AREACODE"	CHAR(3)
,"AUTOCODE"	CHAR(1)
,"CENTSTATUS"	INTEGER EXTERNAL(2)
,"CITYCODE"	CHAR(3)
,"CODE"	CHAR(17)
,"CURRSTATUS"	INTEGER EXTERNAL(2)
,"ENDDATE"	CHAR(8) date_format DATE mask "yyyymmdd"
,"FORMALNAME"	CHAR(120)
,"IFNSFL"	CHAR(4)
,"IFNSUL"	CHAR(4)
,"NEXTID"	CHAR(36)
,"OFFNAME"	CHAR(120)
,"OKATO"	CHAR(11)
,"OKTMO"	CHAR(11)
,"OPERSTATUS"	INTEGER EXTERNAL(2)
,"PARENTGUID"	CHAR(36)
,"PLACECODE"	CHAR(3)
,"PLAINCODE"	CHAR(15)
,"POSTALCODE"	CHAR(6)
,"PREVID"	CHAR(36)
,"REGIONCODE"	CHAR(2)
,"SHORTNAME"	CHAR(10)
,"STARTDATE"	CHAR(8) date_format DATE mask "yyyymmdd"
,"STREETCODE"	CHAR(4)
,"TERRIFNSFL"	CHAR(4)
,"TERRIFNSUL"	CHAR(4)
,"UPDATEDATE"	CHAR(8) date_format DATE mask "yyyymmdd"
,"CTARCODE"	CHAR(3)
,"EXTRCODE"	CHAR(4)
,"SEXTCODE"	CHAR(3)
,"LIVESTATUS"	INTEGER EXTERNAL(2)
,"NORMDOC"	CHAR(36)
,"PLANCODE"	CHAR(4)
,"CADNUM"	CHAR(100)
,"DIVTYPE"	INTEGER EXTERNAL(1)
                )
          )
          location('ADDROB01.DBF')
        ) REJECT LIMIT 0;
```

##create table organization external over .dbf files

###command
```sql
BEGIN
    /* create table organization external over .dbf files
       for the first execution of each filename.dbf, it fails and ask to grant execution permission for preprocessor file that have just been generated (see dbms_output)
       for the next execution, it checks selection from the have been created external table
    */
    dbase_fox.createExternalTable('ADDROB01.DBF','ADDROB01.DBF,ADDROB02.DBF');
END;
/
```

###output on first run:

```sql
file: DBF_FILES/ADDROB01.DBF

DBASE File	Version	Year	Month	Day	#Recs	HdrLen	RecLen	#Fields	Size	CodePage
============	=======	====	=====	===	=====	======	======	=======	====	========
ADDROB01.DBF	3	2049	1	1	20082	1281	710	39	14259502	101 (RU8PC866)

Preprocessor:
#!/bin/sh
/usr/bin/tail -c +1282 $1 | /usr/bin/head -c -1


Create table organization EXTERNAL statement:

create table stage_ADDROB01_ext (
 DELETE_FLAG VARCHAR2(1), 
"ACTSTATUS"	number(2)
,"AOGUID"	varchar2(36)
,"AOID"	varchar2(36)
,"AOLEVEL"	number(2)
,"AREACODE"	varchar2(3)
,"AUTOCODE"	varchar2(1)
,"CENTSTATUS"	number(2)
,"CITYCODE"	varchar2(3)
,"CODE"	varchar2(17)
,"CURRSTATUS"	number(2)
,"ENDDATE"	date
,"FORMALNAME"	varchar2(120)
,"IFNSFL"	varchar2(4)
,"IFNSUL"	varchar2(4)
,"NEXTID"	varchar2(36)
,"OFFNAME"	varchar2(120)
,"OKATO"	varchar2(11)
,"OKTMO"	varchar2(11)
,"OPERSTATUS"	number(2)
,"PARENTGUID"	varchar2(36)
,"PLACECODE"	varchar2(3)
,"PLAINCODE"	varchar2(15)
,"POSTALCODE"	varchar2(6)
,"PREVID"	varchar2(36)
,"REGIONCODE"	varchar2(2)
,"SHORTNAME"	varchar2(10)
,"STARTDATE"	date
,"STREETCODE"	varchar2(4)
,"TERRIFNSFL"	varchar2(4)
,"TERRIFNSUL"	varchar2(4)
,"UPDATEDATE"	date
,"CTARCODE"	varchar2(3)
,"EXTRCODE"	varchar2(4)
,"SEXTCODE"	varchar2(3)
,"LIVESTATUS"	number(2)
,"NORMDOC"	varchar2(36)
,"PLANCODE"	varchar2(4)
,"CADNUM"	varchar2(100)
,"DIVTYPE"	number(1)
)
        ORGANIZATION external
        (
          TYPE oracle_loader
          DEFAULT DIRECTORY DBF_FILES
          ACCESS PARAMETERS
          (
            RECORDS FIXED 710
            PREPROCESSOR 'dbf_to_flat_preprocessor_ADDROB01.sh'
            CHARACTERSET RU8PC866
            STRING SIZES ARE IN BYTES
            NOBADFILE
            NOLOGFILE
            READSIZE 1048576
            FIELDS
                (
 DELETE_FLAG CHAR(1), 
"ACTSTATUS"	INTEGER EXTERNAL(2)
,"AOGUID"	CHAR(36)
,"AOID"	CHAR(36)
,"AOLEVEL"	INTEGER EXTERNAL(2)
,"AREACODE"	CHAR(3)
,"AUTOCODE"	CHAR(1)
,"CENTSTATUS"	INTEGER EXTERNAL(2)
,"CITYCODE"	CHAR(3)
,"CODE"	CHAR(17)
,"CURRSTATUS"	INTEGER EXTERNAL(2)
,"ENDDATE"	CHAR(8) date_format DATE mask "yyyymmdd"
,"FORMALNAME"	CHAR(120)
,"IFNSFL"	CHAR(4)
,"IFNSUL"	CHAR(4)
,"NEXTID"	CHAR(36)
,"OFFNAME"	CHAR(120)
,"OKATO"	CHAR(11)
,"OKTMO"	CHAR(11)
,"OPERSTATUS"	INTEGER EXTERNAL(2)
,"PARENTGUID"	CHAR(36)
,"PLACECODE"	CHAR(3)
,"PLAINCODE"	CHAR(15)
,"POSTALCODE"	CHAR(6)
,"PREVID"	CHAR(36)
,"REGIONCODE"	CHAR(2)
,"SHORTNAME"	CHAR(10)
,"STARTDATE"	CHAR(8) date_format DATE mask "yyyymmdd"
,"STREETCODE"	CHAR(4)
,"TERRIFNSFL"	CHAR(4)
,"TERRIFNSUL"	CHAR(4)
,"UPDATEDATE"	CHAR(8) date_format DATE mask "yyyymmdd"
,"CTARCODE"	CHAR(3)
,"EXTRCODE"	CHAR(4)
,"SEXTCODE"	CHAR(3)
,"LIVESTATUS"	INTEGER EXTERNAL(2)
,"NORMDOC"	CHAR(36)
,"PLANCODE"	CHAR(4)
,"CADNUM"	CHAR(100)
,"DIVTYPE"	INTEGER EXTERNAL(1)
                )
          )
          location('ADDROB01.DBF','ADDROB02.DBF')
        ) REJECT LIMIT 0;

Save preprocessor to file dbf_to_flat_preprocessor_ADDROB01.sh...
OK

Creating external table stage_ADDROB01_ext...
OK

Selecting from external table stage_ADDROB01_ext...
YOU HAVE TO MANUALLY SET EXEC PERMISSION TO FILE USING THIS COMMAND IN UNIX:
chmod u+x /tmp/dbf_to_flat_preprocessor_ADDROB01.sh
Error: ORA-29913: error in executing ODCIEXTTABLEFETCH callout
ORA-29400: data cartridge error
KUP-04095: preprocessor command /tmp/dbf_to_flat_preprocessor_ADDROB01.sh encountered error "error during exec: errno is 13
"
```

###after executing
```sh
chmod u+x /tmp/dbf_to_flat_preprocessor_ADDROB01.sh
```

###, output on second run:

```sql
file: DBF_FILES/ADDROB01.DBF

DBASE File	Version	Year	Month	Day	#Recs	HdrLen	RecLen	#Fields	Size	CodePage
============	=======	====	=====	===	=====	======	======	=======	====	========
ADDROB01.DBF	3	2049	1	1	20082	1281	710	39	14259502	101 (RU8PC866)

Preprocessor:
#!/bin/sh
/usr/bin/tail -c +1282 $1 | /usr/bin/head -c -1


Create table organization EXTERNAL statement:

create table stage_ADDROB01_ext (
 DELETE_FLAG VARCHAR2(1), 
"ACTSTATUS"	number(2)
,"AOGUID"	varchar2(36)
,"AOID"	varchar2(36)
,"AOLEVEL"	number(2)
,"AREACODE"	varchar2(3)
,"AUTOCODE"	varchar2(1)
,"CENTSTATUS"	number(2)
,"CITYCODE"	varchar2(3)
,"CODE"	varchar2(17)
,"CURRSTATUS"	number(2)
,"ENDDATE"	date
,"FORMALNAME"	varchar2(120)
,"IFNSFL"	varchar2(4)
,"IFNSUL"	varchar2(4)
,"NEXTID"	varchar2(36)
,"OFFNAME"	varchar2(120)
,"OKATO"	varchar2(11)
,"OKTMO"	varchar2(11)
,"OPERSTATUS"	number(2)
,"PARENTGUID"	varchar2(36)
,"PLACECODE"	varchar2(3)
,"PLAINCODE"	varchar2(15)
,"POSTALCODE"	varchar2(6)
,"PREVID"	varchar2(36)
,"REGIONCODE"	varchar2(2)
,"SHORTNAME"	varchar2(10)
,"STARTDATE"	date
,"STREETCODE"	varchar2(4)
,"TERRIFNSFL"	varchar2(4)
,"TERRIFNSUL"	varchar2(4)
,"UPDATEDATE"	date
,"CTARCODE"	varchar2(3)
,"EXTRCODE"	varchar2(4)
,"SEXTCODE"	varchar2(3)
,"LIVESTATUS"	number(2)
,"NORMDOC"	varchar2(36)
,"PLANCODE"	varchar2(4)
,"CADNUM"	varchar2(100)
,"DIVTYPE"	number(1)
)
        ORGANIZATION external
        (
          TYPE oracle_loader
          DEFAULT DIRECTORY DBF_FILES
          ACCESS PARAMETERS
          (
            RECORDS FIXED 710
            PREPROCESSOR 'dbf_to_flat_preprocessor_ADDROB01.sh'
            CHARACTERSET RU8PC866
            STRING SIZES ARE IN BYTES
            NOBADFILE
            NOLOGFILE
            READSIZE 1048576
            FIELDS
                (
 DELETE_FLAG CHAR(1), 
"ACTSTATUS"	INTEGER EXTERNAL(2)
,"AOGUID"	CHAR(36)
,"AOID"	CHAR(36)
,"AOLEVEL"	INTEGER EXTERNAL(2)
,"AREACODE"	CHAR(3)
,"AUTOCODE"	CHAR(1)
,"CENTSTATUS"	INTEGER EXTERNAL(2)
,"CITYCODE"	CHAR(3)
,"CODE"	CHAR(17)
,"CURRSTATUS"	INTEGER EXTERNAL(2)
,"ENDDATE"	CHAR(8) date_format DATE mask "yyyymmdd"
,"FORMALNAME"	CHAR(120)
,"IFNSFL"	CHAR(4)
,"IFNSUL"	CHAR(4)
,"NEXTID"	CHAR(36)
,"OFFNAME"	CHAR(120)
,"OKATO"	CHAR(11)
,"OKTMO"	CHAR(11)
,"OPERSTATUS"	INTEGER EXTERNAL(2)
,"PARENTGUID"	CHAR(36)
,"PLACECODE"	CHAR(3)
,"PLAINCODE"	CHAR(15)
,"POSTALCODE"	CHAR(6)
,"PREVID"	CHAR(36)
,"REGIONCODE"	CHAR(2)
,"SHORTNAME"	CHAR(10)
,"STARTDATE"	CHAR(8) date_format DATE mask "yyyymmdd"
,"STREETCODE"	CHAR(4)
,"TERRIFNSFL"	CHAR(4)
,"TERRIFNSUL"	CHAR(4)
,"UPDATEDATE"	CHAR(8) date_format DATE mask "yyyymmdd"
,"CTARCODE"	CHAR(3)
,"EXTRCODE"	CHAR(4)
,"SEXTCODE"	CHAR(3)
,"LIVESTATUS"	INTEGER EXTERNAL(2)
,"NORMDOC"	CHAR(36)
,"PLANCODE"	CHAR(4)
,"CADNUM"	CHAR(100)
,"DIVTYPE"	INTEGER EXTERNAL(1)
                )
          )
          location('ADDROB01.DBF','ADDROB02.DBF')
        ) REJECT LIMIT 0;

Save preprocessor to file dbf_to_flat_preprocessor_ADDROB01.sh...
OK

Creating external table stage_ADDROB01_ext...
OK

Selecting from external table stage_ADDROB01_ext...
OK
```