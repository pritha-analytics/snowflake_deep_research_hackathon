USE SCHEMA WAR_ROOM.OPS;

CREATE OR REPLACE SECRET github_secret
  TYPE = PASSWORD
  USERNAME = 'pritha-analytics'
  PASSWORD = ;

CREATE OR REPLACE API INTEGRATION github_api_int
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/pritha-analytics')
  ALLOWED_AUTHENTICATION_SECRETS = (WAR_ROOM.OPS.github_secret)
  ENABLED = TRUE;