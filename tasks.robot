*** Settings ***
Documentation     Execution report
Resource          SAP.resource
Resource          Salesforce.resource

*** Tasks ***
List accounts from SAP
    SAP Gui Login
    SAP Get List of Customers
    [Teardown]    SAP Graceful Exit

*** Tasks ***
List accounts from Salesforce
    Salesforce API Authorize
    Salesforce List Accounts
    Salesforce Account Screenshots

*** Tasks ***
List accounts from Salesforce (no browser)
    Salesforce API Authorize
    ${accounts}=    Salesforce List Accounts
    Salesforce Account Screenshots With API    ${accounts}

*** Tasks ***
Compare Salesforce and SAP accounts
    [Setup]    Google Drive Initialization
    SAP Gui Login
    SAP Compare Against Salesforce Accounts
    [Teardown]    SAP Graceful Exit

*** Tasks ***
Create New Accounts to Salesforce
    Salesforce API Authorize
    Salesforce Add or Update Accounts

*** Tasks ***
Fix comparison errors
    ${rows}=    Get Comparison Excel from Google Drive
    ${response}=    Create Form For User    ${rows}
    Robocloud Start Fix Process    ${response}    ${rows}

*** Tasks ***
Fix Account Name in SFDC
    Salesforce API Authorize
    ${vars}=    Get Work Item Variables
    Salesforce Create or Modify Accounts    ${vars}
