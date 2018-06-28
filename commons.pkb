create or replace PACKAGE BODY COMMONS AS
	FUNCTION UTIL_GET_XML_FROM_REFCUR(p_refcur sys_refcursor) RETURN xmltype AS 	
	/*	
		Function;				UTIL_GET_XML_FROM_REFCUR
		Status:					
		Author: 				Robert Čmrlec
		Created:				19.06.2018
		Purpuse:				return xml from sys_refcursor
		Revisions:				1.0
		Parameters:				p_refcur refernce cursor
		References:				
		Referenced by:			
		Out parameter: 			xml
	*/	
		v_Return clob;
		v_xml	xmltype;
		spr varchar(4000);
		spr1 varchar(4000);
	BEGIN
		return xmltype(p_refcur);
	END UTIL_GET_XML_FROM_REFCUR;
	
	FUNCTION UTIL_GET_CLOB_FROM_REFCUR(p_refcur sys_refcursor) RETURN clob AS 	
	/*	
		Function;				UTIL_GET_CLOB_FROM_REFCUR
		Status:					
		Author: 				Robert Čmrlec
		Created:				19.06.2018
		Purpuse:				return clob wiht xml from sys_refcursor
		Revisions:				1.0
		Parameters:				p_refcur refernce cursor
		References:				
		Referenced by:			
		Out parameter: 			xml clob
	*/		
		v_Return clob;
		v_xml	xmltype;
		spr varchar(4000);
		spr1 varchar(4000);
	BEGIN
		return xmltype(p_refcur).getclobval();
	END UTIL_GET_CLOB_FROM_REFCUR;	
	
	
	
	FUNCTION UTIL_EXPORT_CLOB_TO_FILE(	p_clob 				in clob, 
										p_directory_name	in varchar2,
										p_file_name			in varchar2,
										p_header			in clob,
										p_footer			in clob
									 ) RETURN VARCHAR2 IS
	/*	
		Function;				UTIL_EXPORT_CLOB_TO_FILE
		Status:					
		Author: 				Robert Čmrlec
		Created:				19.06.2018
		Purpuse:				save clob to file on database server
		Revisions:				1.0
		Parameters:				p_clob 				data to save
								p_directory_name	oracle directory where the file will go
								p_file_name			file name 
								p_header			this will appear in front of the main clob
								p_footer			this will appear after the main clob
		References:				
		Referenced by:			
		Out parameter: 			returns OK
	*/											 
	  f     UTL_FILE.FILE_TYPE;
	  cpos  pls_integer := 1;											
	BEGIN
		f := utl_file.fopen(p_directory_name, p_file_name, 'w' , 32767);
		utl_file.put(f,p_header);
		utl_file.fflush(f);
		
		while cpos < dbms_lob.getlength(p_clob) loop
			utl_file.put(f,dbms_lob.substr(p_clob, 4000, cpos));
			cpos := cpos + 4000;
			utl_file.fflush(f);
		end loop;
		utl_file.put(f,p_footer);		
		utl_file.fflush(f);
		utl_file.fclose(f);
		RETURN 'OK';
	exception when others then
		utl_file.fclose(f);
		raise;
	END UTIL_EXPORT_CLOB_TO_FILE;	
	
	FUNCTION UTIL_GET_HTML_TABLE(	P_SQL 		IN CLOB, 
									P_CAPTION 	IN VARCHAR2, 
									P_ID 		IN VARCHAR2, 
									P_FOOTER 	IN VARCHAR2
								) RETURN CLOB IS
	/*	
		Function;				UTIL_GET_HTML_TABLE
		Status:					
		Author: 				Robert Čmrlec
		Created:				19.06.2018
		Purpuse:				generates html table . 
		Revisions:				1.0
		Parameters:				P_SQL		SQL with data 
								P_CAPTION	Header of table
								P_ID		Unique ID of table
								P_FOOTER	Description of the table
		References:				
		Referenced by:			UTIL_GET_HTML_TABLE
		Out parameter: 			html table
	*/														  
	l_html_return 				clob;
	l_html_table		 		clob;
	l_html_column_header 		clob;
	l_html_column_header_tmp	clob;
	l_html_row_values			clob;
	l_html_row_values_tmp		clob;
	
	v_curid 		number; 				-- id of the cursor
	l_col_cnt		number;					-- number of columns in the query
	l_rec_tab   	dbms_sql.desc_tab;		-- record specification for query (datatypes ...)
	rows_processed 	number;				-- rows processed
	rows_fetched	number;				-- rows processed
	
	l_number 	number;
	l_varchar2	varchar2(4000);
	l_date		date;
	BEGIN
	
		l_html_table:=q'[<table id="<<id>>"> 
			<caption><<caption>></caption>	
			<TR bgcolor="#e6faff"><<column_header>></TR>]';
		
		l_html_table:=replace(l_html_table, '<<caption>>', '<font size="5px" style="color:#80e5ff;">' || P_CAPTION || '</font>');
		l_html_table:=replace(l_html_table, '<<id>>', P_ID);
		
		
		
		l_html_column_header:=q'[
			<th>
				<<column_header>> 
			</th>]';
		
		l_html_row_values:=q'[<td>
				<<rows>> 
			</td>]';
	
	-- Open cursor and get query structure
		v_curid := dbms_sql.open_cursor;
		DBMS_SQL.PARSE(v_curid, P_SQL, DBMS_SQL.NATIVE);
		DBMS_SQL.DESCRIBE_COLUMNS(v_curid, l_col_cnt, l_rec_tab);
			
		for i in 1 .. l_col_cnt 
		loop
			-- define column headers	
			l_html_column_header_tmp:=l_html_column_header_tmp|| replace(l_html_column_header, '<<column_header>>', l_rec_tab(i).col_name);
			
			-- define column types add additional types
			if l_rec_tab(i).col_type=1 then			
				DBMS_SQL.DEFINE_COLUMN(v_curid, i, l_varchar2, 4000);
			elsif l_rec_tab(i).col_type=2 then
				DBMS_SQL.DEFINE_COLUMN(v_curid, i, l_number);
			elsif l_rec_tab(i).col_type=12 then
				DBMS_SQL.DEFINE_COLUMN(v_curid, i, l_date);
			else
				raise_application_error(-20001, 'UTIL_GET_HTML_TABLE Type not supported');
			end if;
		end loop;
		
		-- get data from cursor
			-- execute cursor
		rows_processed := dbms_sql.execute(v_curid);
			-- fetch values from cursor add additional types
		while DBMS_SQL.FETCH_ROWS(v_curid) > 0 
		loop        
			l_html_row_values_tmp:=l_html_row_values_tmp||'<tr>';
			FOR i IN 1 .. l_col_cnt LOOP
					IF (l_rec_tab(i).col_type = 1) THEN
							DBMS_SQL.COLUMN_VALUE(v_curid, i, l_varchar2);		
							l_html_row_values_tmp:=l_html_row_values_tmp||replace(l_html_row_values,'<<rows>>',l_varchar2);
					ELSIF (l_rec_tab(i).col_type = 2) THEN
							DBMS_SQL.COLUMN_VALUE(v_curid, i, l_number);
							l_html_row_values_tmp:=l_html_row_values_tmp||replace(l_html_row_values,'<<rows>>',l_number);
					ELSIF (l_rec_tab(i).col_type = 12) THEN
							DBMS_SQL.COLUMN_VALUE(v_curid, i, l_date);
							l_html_row_values_tmp:=l_html_row_values_tmp||replace(l_html_row_values,'<<rows>>',l_date);
					END IF;
			END LOOP;
			l_html_row_values_tmp:=l_html_row_values_tmp||'</tr>';
		end loop;
		
		
		-- Close cursor	
		DBMS_SQL.CLOSE_CURSOR(v_curid);			
	
	
	-- replace column_header and rows
		l_html_return:=replace(l_html_table,'<<column_header>>',l_html_column_header_tmp);
		
		l_html_return:=l_html_return||' '||l_html_row_values_tmp||'</table>';
		--replace(l_html_return,'<<rows>>',l_html_row_values_tmp);
		
	-- add footer	
		l_html_return:=l_html_return||'<b>'||'<p style="color:red">'||P_FOOTER||'</b>';
		return l_html_return;
	END UTIL_GET_HTML_TABLE;
	
	FUNCTION UTIL_GET_HTML(		P_DIRECTORY			IN VARCHAR2,
								P_FILENAME			IN VARCHAR2,
								P_HTML_TITLE		IN VARCHAR2,
								P_HTML_HEADER		IN VARCHAR2,
								P_HTML_PARAMETERS	IN VARCHAR2,
								P_TABLE_SQL 		IN CLOB, 
								P_TABLE_CAPTION 	IN VARCHAR2, 
								P_TABLE_ID 			IN VARCHAR2, 
								P_TABLE_FOOTER 		IN VARCHAR2
							) RETURN CLOB AS
		/*	
			Function;				UTIL_GET_HTML
			Status:					OK
			Author: 				Robert Čmrlec
			Created:				28.06.2018
			Purpuse:				generates inserts statements based on given select
			Revisions:				1.0
			Parameters:				P_DIRECTORY			oracle directory where the file will go. 
									P_FILENAME			file name
									P_HTML_TITLE		tab title in the browser
									P_HTML_HEADER		header in html
									P_HTML_PARAMETERS	parameters used to generate html (just for info)
									P_TABLE_SQL 		this is the main thing, the query that generates data displayed in html
									P_TABLE_CAPTION 	caption of the table in html
									P_TABLE_ID 			id of the table in html. 
									P_TABLE_FOOTER 		text displayed after html table											
			References:			
			Referenced by:	
			Out parameter: 	
		*/								
	l_html_start 	CLOB;
	l_html_stop 	CLOB;
	l_clob_table	CLOB;
	l_clob_return	CLOB;
	l_export_OK		varchar2(2000);
	BEGIN
			l_html_start:=q'[<!DOCTYPE html>
									<html>
										<head>
											<meta charset="UTF-8">
											<title><<P_HTML_TITLE>></title>
											<style>
												table {
													font-family: arial, sans-serif;
													border-collapse: collapse;
													width: 100%;
												}
			
												td, th {
													border: 1px solid #dddddd;
													text-align: left;
													padding: 8px;
												}
			
												tr:nth-child(even) {
													background-color: #e6fefe;
												}
											</style>
										</head>
										<body>
												<meta charset="UTF-8">
												<<l_html_parameters>>
												<h1 align="center" style="color:#1ad1ff;"> <font size="12px"> <<P_HTML_HEADER>> </font> <br></h1>
									]';		
			l_html_stop:=q'[			</body>
									</html>
									]';	
	
			l_html_start:=replace(l_html_start,'<<P_HTML_HEADER>>', P_HTML_HEADER);
			l_html_start:=replace(l_html_start,'<<P_HTML_TITLE>>',	P_HTML_TITLE);
			l_html_start:=replace(l_html_start,'<<l_html_parameters>>', P_HTML_PARAMETERS);
			
			l_clob_table := l_clob_table|| UTIL_GET_HTML_TABLE(
													P_SQL => 		P_TABLE_SQL,
													P_CAPTION => 	P_TABLE_CAPTION,
													P_ID => 		P_TABLE_ID,
													P_FOOTER =>		P_TABLE_FOOTER
												  );
			l_clob_table:=l_clob_table||'<BR>';												  
			l_clob_return:=l_html_start||l_clob_table||l_html_stop;
			
			if p_directory is not null and P_FILENAME is not null then
					l_export_OK:=commons.UTIL_EXPORT_CLOB_TO_FILE(	
														p_clob				=>	l_clob_return,
														p_directory_name	=>	p_directory,
														p_file_name			=>	P_FILENAME,
														p_header			=>	null,
														p_footer			=>	null
													 );
			end if;
			
		RETURN l_clob_return;
	END UTIL_GET_HTML;
	
  FUNCTION UTIL_GEN_INSERTS
	(
	  p_sql                     clob, 
	  p_new_owner_name          varchar2 default null,
	  p_new_table_name          varchar2,	  
	  p_delimiter				varchar2
	)
	return clob	
	is
		/*	
			Function;				util_fn_gen_inserts
			Status:					needs testing
			Author: 				Unknown. I got this from internet. It was slow -> I made redesign and forgot where the source came from
			Created:				18.04.2018
			Purpuse:				generates inserts statements based on given select
			Revisions:				1.0
			Parameters:				p_sql					sql which retrieves data
									p_new_table_name		new table name 
									p_new_owner_name		new owner
									p_delimiter				delimiter after insert. usually ;
			References:			
			Referenced by:	
			Out parameter: 	
		*/	
	  l_cur                        number;
	  NL                           varchar2(2) := chr(13)||chr(10);
	  l_sql                        clob := p_sql;
	  l_ret                        number;
	  l_col_cnt                    number;
	  l_rec_tab                    dbms_sql.desc_tab;
	
	  l_separator                  char(1) := '!';
	  l_clob                       clob;
	  l_clob_line                  clob;
	  l_clob_ins                   clob;
	  l_clob_all                   clob;
	  l_clob_return                clob;
	  l_clob_insert_statement	   clob;
	  l_line                       clob := '-----------------------------------';
	
	  cons_date_frm                varchar2(32) := 'DD.MM.YYYY HH24:MI:SS';
	  cons_timestamp_frm           varchar2(32) := 'DD.MM.YYYY HH24:MI:SSXFF';
	  cons_timestamp_wtz_frm       varchar2(32) := 'DD.MM.YYYY HH24:MI:SSXFF TZR';
	
	  cons_varchar2_code           number := 1;
	  cons_nvarchar2_code          number := 1;
	  cons_number_code             number := 2;
	  cons_float_code              number := 2;
	  cons_long_code               number := 8;
	  cons_date_code               number := 12;
	  cons_binary_float_code       number := 100;
	  cons_binary_double_code      number := 101;
	  cons_timestamp_code          number := 180;
	  cons_timestamp_wtz_code      number := 181;
	  cons_timestamp_lwtz_code     number := 231;
	  cons_interval_ytm_code       number := 182;
	  cons_interval_dts_code       number := 183;
	  cons_raw_code                number := 23;
	  cons_long_raw_code           number := 24;
	  cons_rowid_code              number := 11;
	  cons_urowid_code             number := 208;
	  cons_char_code               number := 96;
	  cons_nchar_code              number := 96;
	  cons_clob_code               number := 112;
	  cons_nclob_code              number := 112;
	  cons_blob_code               number := 113;
	  cons_bfile_code              number := 114;
	
	  -------------------------------------
	  -- Supported types
	  -------------------------------------
	  l_varchar2_col                varchar2(32767); --1
	  l_number_col                  number;          --2
	  --l_long_col                    long;          --8 - not supported
	  l_date_col                    date;            --12
	  --l_raw_col                     raw(2000);     --23 - not supported
	  l_rowid_col                   rowid;           --69
	  l_char_col                    char(2000);      --96
	  l_binary_float_col            binary_float;    --100
	  l_binary_double_col           binary_double;   --101
	  l_clob_col                    clob;            --112
	  l_timestamp_col               timestamp(9);    --180
	  l_timestamp_wtz_col           timestamp(9) with time zone;    --181
	  l_interval_ytm_col            interval year(9) to month;      --182
	  l_interval_dts_col            interval day(9) to second(2);   --183
	  l_urowid_col                  urowid;                         --208
	  l_timestamp_wltz_col          timestamp with local time zone; --231

	  lv_list_of_columns varchar2(4000);
	  
	  loc_n number;
	  loc_v varchar2(255);
	  l_n number;
	  
	  l_tmp_cnt number;
	
	  procedure print_rec(rec in dbms_sql.desc_rec) is
	  begin
		l_clob_all := l_clob_all||NL||
		  'col_type            =    ' || rec.col_type||NL||
		  'col_maxlen          =    ' || rec.col_max_len||NL||
		  'col_name            =    ' || rec.col_name||NL||
		  'col_name_len        =    ' || rec.col_name_len||NL||
		  'col_schema_name     =    ' || rec.col_schema_name||NL||
		  'col_schema_name_len =    ' || rec.col_schema_name_len||NL||
		  'col_precision       =    ' || rec.col_precision||NL||
		  'col_scale           =    ' || rec.col_scale||NL||
		  'col_null_ok         =    ';
	
		if (rec.col_null_ok) then
		  l_clob_all := l_clob_all||'true'||NL;
		else
		  l_clob_all := l_clob_all||'false'||NL;
		end if;
	  end;  
	begin
	
	
	  ---------------------------------------
	  -- Introduction
	  ---------------------------------------
	  -- l_clob_all := l_clob_all||l_line||NL||'Parsing query:'||NL||l_sql||NL;
	
	  ---------------------------------------
	  -- Open parse cursor
	  ---------------------------------------
	  l_cur := dbms_sql.open_cursor;
	  dbms_sql.parse(l_cur, l_sql, dbms_sql.native);
	
	  ---------------------------------------
	  -- Describe columns
	  ---------------------------------------
	  
	  dbms_sql.describe_columns(l_cur, l_col_cnt, l_rec_tab);
	
	
	  ---------------------------------------
	  -- Define columns
	  ---------------------------------------
  
	  
	  for i in 1..l_rec_tab.count  
	  loop
		if    l_rec_tab(i).col_type = cons_varchar2_code then --varchar2
		  dbms_sql.define_column(l_cur, i, l_varchar2_col, l_rec_tab(i).col_max_len); 
		elsif l_rec_tab(i).col_type = cons_number_code then --number
		  dbms_sql.define_column(l_cur, i, l_number_col); 
		elsif l_rec_tab(i).col_type = cons_date_code then --date
		  dbms_sql.define_column(l_cur, i, l_date_col); 
		elsif l_rec_tab(i).col_type = cons_binary_float_code then --binary_float
		  dbms_sql.define_column(l_cur, i, l_binary_float_col); 
		elsif l_rec_tab(i).col_type = cons_binary_double_code then --binary_double
		  dbms_sql.define_column(l_cur, i, l_binary_double_col); 
		elsif l_rec_tab(i).col_type = cons_rowid_code then  --rowid
		  dbms_sql.define_column_rowid(l_cur, i, l_rowid_col); 
		elsif l_rec_tab(i).col_type = cons_char_code then  --char
		  dbms_sql.define_column_char(l_cur, i, l_char_col, l_rec_tab(i).col_max_len); 
		elsif l_rec_tab(i).col_type = cons_clob_code then --clob
		  dbms_sql.define_column(l_cur, i, l_clob_col); 
		elsif l_rec_tab(i).col_type = cons_timestamp_code then --timestamp
		  dbms_sql.define_column(l_cur, i, l_timestamp_col); 
		elsif l_rec_tab(i).col_type = cons_timestamp_wtz_code then --timestamp with time zone
		  dbms_sql.define_column(l_cur, i, l_timestamp_wtz_col); 
		elsif l_rec_tab(i).col_type = cons_rowid_code then --urowid
		  dbms_sql.define_column(l_cur, i, l_urowid_col); 
		elsif l_rec_tab(i).col_type = cons_timestamp_lwtz_code then --timestamp with local time zone
		  dbms_sql.define_column(l_cur, i, l_timestamp_wltz_col); 
		elsif l_rec_tab(i).col_type = cons_interval_ytm_code then --interval year to month
		  dbms_sql.define_column(l_cur, i, l_interval_ytm_col); 
		elsif l_rec_tab(i).col_type = cons_interval_dts_code then --interval day to second
		  dbms_sql.define_column(l_cur, i, l_interval_dts_col); 
		elsif l_rec_tab(i).col_type = cons_urowid_code then --urowid
		  dbms_sql.define_column(l_cur, i, l_urowid_col); 
		else
		  raise_application_error(-20001, 'Column: '||l_rec_tab(i).col_name||NL||
										  'Type not supported: '||l_rec_tab(i).col_type);
		  --not supported
		end if;

		lv_list_of_columns:=lv_list_of_columns||'	' || l_rec_tab(i).col_name || ','||chr(13);
				
	end loop;
	
	
	  ---------------------------------------
	  -- Define insert statement
	  ---------------------------------------	
	lv_list_of_columns:=substr(lv_list_of_columns,1,length(lv_list_of_columns)-2);
	  
	if p_new_owner_name is null then
		l_clob_all := l_clob_all||chr(13)||NL||
			  'insert into '||p_new_table_name||'('||lv_list_of_columns||')'||' '||
			  'values ('
			  ;
	else
		l_clob_all := l_clob_all||chr(13)||NL||
			  'insert into '||p_new_owner_name||'.'||p_new_table_name||'('||lv_list_of_columns||
			   ')'||
				' values ('
					;
	end if;	

	  ---------------------------------------
	  -- Add data to insert statement
	  ---------------------------------------
	
	l_ret := dbms_sql.execute(l_cur);	
	loop
		l_ret := dbms_sql.fetch_rows(l_cur);
		l_clob_insert_statement := l_clob_all;
		for i in 1 .. l_rec_tab.count
		loop
				if    l_rec_tab(i).col_type = cons_varchar2_code then --varchar2
					dbms_sql.column_value(l_cur, i, l_varchar2_col); 
					l_clob := l_varchar2_col;
					if l_clob is null then
						l_clob:='NULL';
					end if;
					l_clob_insert_statement := l_clob_insert_statement||''''||replace(l_varchar2_col,'''','''''' )||''''||',';
				elsif l_rec_tab(i).col_type = cons_number_code then --number
					dbms_sql.column_value(l_cur, i, l_number_col); 
					l_clob := REPLACE(to_char(l_number_col), ',' , '.' );
					if l_clob is null then
						l_clob:='NULL';
					end if;					
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';
				elsif l_rec_tab(i).col_type = cons_date_code then --date
					dbms_sql.column_value(l_cur, i, l_date_col); 					
					l_clob := 'TO_DATE('||''''||to_char(l_date_col, cons_date_frm)||''''||','||''''||cons_date_frm||''''||')';
					if l_clob is null then
						l_clob:='NULL';
					end if;					
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';
				elsif l_rec_tab(i).col_type = cons_binary_float_code then --binary_float
					dbms_sql.column_value(l_cur, i, l_binary_float_col); 
					l_clob := to_char(l_binary_float_col);
					if l_clob is null then
						l_clob:='NULL';
					end if;					
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';
				elsif l_rec_tab(i).col_type = cons_binary_double_code then --binary_double
					dbms_sql.column_value(l_cur, i, l_binary_double_col); 
					l_clob := to_char(l_binary_double_col);
					if l_clob is null then
						l_clob:='NULL';
					end if;					
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';
				elsif l_rec_tab(i).col_type = cons_rowid_code then --rowid
					dbms_sql.column_value(l_cur, i, l_rowid_col); 
					l_clob := to_char(l_rowid_col);
					if l_clob is null then
						l_clob:='NULL';
					end if;					
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';
				elsif l_rec_tab(i).col_type = cons_char_code then --char
					dbms_sql.column_value_char(l_cur, i, l_char_col); 
					l_tmp_cnt:=l_rec_tab(i).col_max_len;
					if l_tmp_cnt=1 then
						l_clob := ''''||substr(l_char_col, 1, 1)||'''';	
					else
						l_clob := ''''||substr(l_char_col, 1, l_rec_tab(i).col_max_len)||'''';
					end if;
					
					l_tmp_cnt:=length(l_clob);
					if l_clob is null then
						l_clob:='NULL';
					end if;					
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';
					null;
				elsif l_rec_tab(i).col_type = cons_clob_code then --clob
					dbms_sql.column_value(l_cur, i, l_clob_col); 
					l_clob := l_clob_col;
					if l_clob is null then
						l_clob:='NULL';
					else
						l_clob := COMMONS.SHREDCLOB(
							PCLOB => l_clob,
							pchunkSize => 3900
						);				
					end if;				
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';											
				elsif l_rec_tab(i).col_type = cons_timestamp_code then --timestamp
					dbms_sql.column_value(l_cur, i, l_timestamp_col); 
					l_clob := 'to_char('||''''||l_timestamp_col||''''||','||''''||cons_timestamp_frm||''''||')'||'';
					if l_clob is null then
						l_clob:='NULL';
					end if;
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';					
				elsif l_rec_tab(i).col_type = cons_timestamp_wtz_code then --timestamp with time zone
					dbms_sql.column_value(l_cur, i, l_timestamp_wtz_col); 
					l_clob := 'to_char('||''''||l_timestamp_wtz_col||''''||','||''''||cons_timestamp_wtz_frm||''''||')'||'';
					if l_clob is null then
						l_clob:='NULL';
					end if;					
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';					
				elsif l_rec_tab(i).col_type = cons_interval_ytm_code then --interval year to month
					dbms_sql.column_value(l_cur, i, l_interval_ytm_col); 
					l_clob := to_char(l_interval_ytm_col);
					if l_clob is null then
						l_clob:='NULL';
					end if;					
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';					
				elsif l_rec_tab(i).col_type = cons_interval_dts_code then --interval day to second
					dbms_sql.column_value(l_cur, i, l_interval_dts_col); 
					l_clob := to_char(l_interval_dts_col);
					if l_clob is null then
						l_clob:='NULL';
					end if;					
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';					
				elsif l_rec_tab(i).col_type = cons_urowid_code then --urowid
					dbms_sql.column_value(l_cur, i, l_urowid_col); 
					l_clob := to_char(l_urowid_col);
					if l_clob is null then
						l_clob:='NULL';
					end if;					
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';					
				elsif l_rec_tab(i).col_type = cons_timestamp_lwtz_code then --timestamp with local time zone
					dbms_sql.column_value(l_cur, i, l_timestamp_wltz_col); 
					l_clob := 'to_char('||''''||l_timestamp_wltz_col||''''||','||''''||cons_timestamp_wtz_frm||''''||')'||'';
					if l_clob is null then
						l_clob:='NULL';
					end if;					
					l_clob_insert_statement := l_clob_insert_statement||l_clob||',';					
				end if;
				l_clob_insert_statement:=l_clob_insert_statement	||	CHR(13) ||'	';
				
			end loop;									
			exit when l_ret = 0;
			l_clob_insert_statement:=substr(l_clob_insert_statement,1,length(l_clob_insert_statement)-3)||')';
			l_clob_return:=l_clob_return || chr(13) || l_clob_insert_statement ||chr(13)||p_delimiter;						
			
	end loop;
	
	dbms_sql.close_cursor(l_cur);	
	
	return l_clob_return;
		exception when others then
			if dbms_sql.is_open(l_cur) then
					dbms_sql.close_cursor(l_cur);			
--					l_n:=1/0;					
					return null;
					raise;
			end if; 

			
	end util_gen_inserts;  
	
	
	function shredClob(pClob in clob, pchunkSize in number) return clob is
	locClob Clob;
	loc_numChunk INTEGER;
	loc_chunkSize integer:=pchunkSize;
	od integer;
	do integer;
	
	begin
		if pchunkSize>3991 then
			loc_chunkSize:=3991;
		end if;
			
		loc_numChunk:=ceil(length(pClob)/loc_chunkSize); -- -9 is for to_clob
		
		for i in 1..loc_numChunk+1
		loop
			if i=1 then
				od:=i;
				do:=od+loc_chunkSize-1;
			else
				od:=do+1;
				do:=od+loc_chunkSize-1;
			end if;
			if locClob is null then
				locClob:=locClob||'to_clob('||'q' || '''' || '[' ||substr(pClob,od,loc_chunkSize) || ']' ||''''|| ')';
			else 
				locClob:=locClob||'||'||'to_clob('||'q' || '''' || '[' ||substr(pClob,od,loc_chunkSize) || ']' ||''''|| ')';
			end if;
		end loop;

--		return substr(locClob,1, length(locClob)-2);
		return substr(locClob,1, length(locClob));
	end shredClob;
	
	PROCEDURE UTIL_GET_ENA_DIS_TAB_TRIG(
									P_OWNER 		IN VARCHAR2, 
									P_TABLE_NAME 	IN VARCHAR2,
									P_TYPE			IN VARCHAR2,	-- ENABLED return code for enabled triggers,  ALL return code for all triggers
									P_ENABLE		OUT CLOB,
									P_DISABLE		OUT CLOB
								) AS
		CURSOR C_DISABLE_ENABLED IS SELECT 'ALTER TRIGGER '||OWNER||'.'||TRIGGER_NAME||' DISABLE;' SQL_STAT
							FROM DBA_TRIGGERS
							WHERE TABLE_OWNER=P_OWNER AND TABLE_NAME=P_TABLE_NAME
							AND STATUS='ENABLED'
							;
		CURSOR C_DISABLE_ALL IS SELECT 'ALTER TRIGGER '||OWNER||'.'||TRIGGER_NAME||' DISABLE;' SQL_STAT
							FROM DBA_TRIGGERS
							WHERE TABLE_OWNER=P_OWNER AND TABLE_NAME=P_TABLE_NAME
							;						
		CURSOR C_ENABLE_ENABLED IS SELECT 'ALTER TRIGGER '||OWNER||'.'||TRIGGER_NAME||' ENABLE;' SQL_STAT
							FROM DBA_TRIGGERS
							WHERE TABLE_OWNER=P_OWNER AND TABLE_NAME=P_TABLE_NAME
							AND STATUS='ENABLED'
							;
		CURSOR C_ENABLE_ALL IS SELECT 'ALTER TRIGGER '||OWNER||'.'||TRIGGER_NAME||' ENABLE;' SQL_STAT
							FROM DBA_TRIGGERS
							WHERE TABLE_OWNER=P_OWNER AND TABLE_NAME=P_TABLE_NAME
							;												
	BEGIN
		IF P_TYPE='ALL' THEN
			FOR T IN C_DISABLE_ALL 
			LOOP
				P_DISABLE:=P_DISABLE||T.SQL_STAT||CHR(10);
			END LOOP;
				
			FOR T IN C_ENABLE_ALL 
			LOOP
				P_ENABLE:=P_ENABLE||T.SQL_STAT||CHR(10);
			END LOOP;
		ELSIF P_TYPE='ENABLED' THEN
			FOR T IN C_DISABLE_ENABLED 
			LOOP
				P_DISABLE:=P_DISABLE||T.SQL_STAT||CHR(10);
			END LOOP;
				
			FOR T IN C_ENABLE_ENABLED 
			LOOP
				P_ENABLE:=P_ENABLE||T.SQL_STAT||CHR(10);
			END LOOP;		
		END IF;
	END UTIL_GET_ENA_DIS_TAB_TRIG;	
	
	
END COMMONS;

/*
DECLARE
  P_REFCUR sys_refcursor;
  v_Return XMLTYPE;
  v_xml	xmltype;
  v_clob clob;
BEGIN
    open P_REFCUR for
    SELECT * FROM CAT
	;

	  v_Return := COMMONS.UTIL_GET_XML_FROM_REFCUR(
		P_REFCUR => P_REFCUR
	  );
	v_clob:=v_Return.EXTRACT('/ROWSET/ROW').getclobval();	
	dbms_output.put_line(substr(v_clob,1,32000));
END;
