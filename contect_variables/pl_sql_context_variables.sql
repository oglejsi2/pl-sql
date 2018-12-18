/*
    Creates parameters which can be referenced from views or other procedures
    You have to be carefull with pooled sessions. Pooling recycles sessions -> user a can inherit values from user b
*/

CREATE OR REPLACE CONTEXT sample_ctx USING set_context;


CREATE  PROCEDURE set_context
( pname  VARCHAR2
, pvalue VARCHAR2) IS
BEGIN
  -- Create a session with a previously defined context.
  DBMS_SESSION.SET_CONTEXT('SAMPLE_CTX',pname,pvalue);
END;
/

EXECUTE set_context('email','sherman@atlanta.org');

SELECT sys_context('sample_ctx','email') FROM dual;