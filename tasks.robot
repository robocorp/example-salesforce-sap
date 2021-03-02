*** Settings ***
Documentation     Template robot main suite.
Library           RPA.Robocloud.Secrets
Library           RPA.SAP
Library           CustomSap

*** Tasks ***
Minimal task
    ${secrets}=    Get Secret    sap_db1
    Custom Connector    ${secrets}
    @{rows}=    Custom Query    SELECT * FROM DB_1.COMMUNITY
    Log To Console    ${rows}
    Log    Done.
