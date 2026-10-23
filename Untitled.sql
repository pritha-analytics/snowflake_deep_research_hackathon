USE ROLE ACCOUNTADMIN;
ALTER USER EMEA_TESTER SET
  PASSWORD = 'Amna@Snowflake'      -- replace with your own: 14+ characters, upper and lower case letters, a number
  MUST_CHANGE_PASSWORD = FALSE;

-- Check: PASSWORD_LAST_SET_TIME should show the current time
DESC USER EMEA_TESTER;