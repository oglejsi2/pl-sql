create or replace PACKAGE COMMONS AS 

  /* TODO enter package declarations (types, exceptions, methods etc) here */ 
		FUNCTION UTIL_GET_XML_FROM_REFCUR	(
												p_refcur sys_refcursor
											) RETURN xmltype ;
											
		FUNCTION UTIL_GET_CLOB_FROM_REFCUR	(
												p_refcur sys_refcursor
											) RETURN clob;
											
	
		FUNCTION UTIL_EXPORT_CLOB_TO_FILE(	p_clob 				in clob, 
										p_directory_name	in varchar2,
										p_file_name			in varchar2,
										p_header			in clob,
										p_footer			in clob
									 ) RETURN VARCHAR2;
											
		FUNCTION UTIL_GET_HTML_TABLE		(	P_SQL 		IN CLOB, 
												P_CAPTION 	IN VARCHAR2, 
												P_ID 		IN VARCHAR2, 
												P_FOOTER 	IN VARCHAR2
											) RETURN CLOB;
											
		FUNCTION UTIL_GET_HTML(		P_DIRECTORY			IN VARCHAR2,
									P_FILENAME			IN VARCHAR2,
									P_HTML_TITLE		IN VARCHAR2,
									P_HTML_HEADER		IN VARCHAR2,
									P_HTML_PARAMETERS	IN VARCHAR2,
									P_TABLE_SQL 		IN CLOB, 
									P_TABLE_CAPTION 	IN VARCHAR2, 
									P_TABLE_ID 			IN VARCHAR2, 
									P_TABLE_FOOTER 		IN VARCHAR2
								) RETURN CLOB;
								
	  FUNCTION UTIL_GEN_INSERTS
		(
		  p_sql                     clob, 
		  p_new_owner_name          varchar2 default null,
		  p_new_table_name          varchar2,	  
		  p_delimiter				varchar2
		)
		return clob;
		

		
	  function shredClob
			(
				pClob in clob, 
				pchunkSize in number
			) 
	  return clob;
	  
	PROCEDURE UTIL_GET_ENA_DIS_TAB_TRIG(
									P_OWNER 		IN VARCHAR2, 
									P_TABLE_NAME 	IN VARCHAR2,
									P_TYPE			IN VARCHAR2,	-- ENABLED return code for enabled triggers,  ALL return code for all triggers
									P_ENABLE		OUT CLOB,
									P_DISABLE		OUT CLOB
								) ;	  
END COMMONS;
/