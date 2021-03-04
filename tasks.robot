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
    [Documentation]    Save data into Excel
    Salesforce API Authorize
    Salesforce List Accounts
    Salesforce Account Screenshots

*** Tasks ***
List accounts from Salesforce (no browser)
    [Documentation]    Save data into Excel
    Salesforce API Authorize
    ${accounts}=    Salesforce List Accounts
    Salesforce Account Screenshots With API    ${accounts}

*** Tasks ***
List orders from Salesforce
    [Documentation]    Save data into Excel
    No Operation

*** Tasks ***
List orders from SAP
    [Documentation]    Save data into Excel
    No Operation

*** Tasks ***
Add orders into Salesforce
    No Operation

*** Tasks ***
Add orders into SAP
    No Operation

*** Tasks ***
Compare Salesforce and SAP accounts
    [Documentation]    Missing, differences
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
    [Setup]    Google Drive Initialization
    #WS Get Run Artifact    compare_sfdc_to_sap.xlsx
    ${files}=    Drive Search Files    query=name contains 'compare_sfdc_to_sap.xlsx'    folder_name=aligntech
    Drive Download Files    file_dict=${files}[0]
    Open Workbook    compare_sfdc_to_sap.xlsx
    ${rows}=    Read Worksheet As Table    header=True
    ${missing_errors}=    Create List
    ${name_errors}=    Create List
    FOR    ${row}    IN    @{rows}
        ${account_name}=    Replace String    ${row}[Name in SFDC]    ,    ${EMPTY}
        Run Keyword If    "${row}[Account In SAP]"=="FALSE"
        ...    Append To List
        ...    ${missing_errors}
        ...    ${row}[Account Id] - ${account_name}
        Run Keyword If    "FALSE" in "${row}[Name OK in SFDC]" and "${row}[Account In SAP]"=="TRUE" and "${row}[Name in SAP]" != "None"
        ...    Append To List
        ...    ${name_errors}
        ...    ${row}[Account Id] - ${account_name} [in SAP -> ${row}[Name in SAP]]
    END
    ${missing_string}=    Evaluate    ",".join(${missing_errors})
    ${name_string}=    Evaluate    ",".join(${name_errors})
    Create Form    Validate SFDC accounts against SAP
    Run Keyword If    ${missing_errors}    Add Checkbox    label=Select account to add into SAP
    ...    element_id=missingaccount
    ...    options=${missing_string}
    Run Keyword If    ${name_errors}    Add Checkbox    label=Fix account name in SFDC
    ...    element_id=nameerror
    ...    options=${name_errors}
    &{response}=    Request Response
    Log Many    ${response}
    Copy File    compare_sfdc_to_sap.xlsx    ${EXECDIR}${/}output${/}
    WS Start Fix Process    ${response}    ${rows}

*** Tasks ***
Fix Account Name in SFDC
    Salesforce API Authorize
    ${vars}=    Get Work Item Variables
    FOR    ${cus}    IN    @{vars}
        ${account}=    Salesforce Query Result As Table    SELECT Id FROM Account WHERE AccountNumber = '${cus}[id]'
        ${account_len}=    Get Length    ${account}
        ${obj}=    Create Dictionary    Name=${cus}[name]    AccountNumber=${cus}[id]
        Run Keyword If    ${account_len}==1    Upsert Salesforce Object    Account    ${account}[0][0]    ${obj}
        Run Keyword If    ${account_len}==0    Create Salesforce Object    Account    ${obj}
    END

*** Tasks ***
SAP Create Accounts
    #Log To Console    \n${LOCAL_STORAGE}
    #Set Robocloud Vault    vault_name=googlecloud    vault_secret_key=credentials
    #Init Drive Client    use_robocloud_vault=True
    #Drive Create Directory    aligntech
    #Drive Upload File    compare_sfdc_to_sap.xlsx    aligntech
    ${vars}=    Get Work Item Variables
    Log Many    ${vars}
    #FOR    ${ac}    IN    @{vars}
    #    Log Many    ${ac}
    #END
    #SAP Gui Login
    #[Teardown]    SAP Graceful Exit
    #${folder_id}=    Drive Get Folder Id    aligntech
    #${files}=    Drive Search Files    query=name contains 'compare_sfdc_to_sap.xlsx'    folder_name=aligntech
    #Drive Download Files    file_dict=${files}[0]

*** Tasks ***
Check Work Item Payload
    ${payload}=    Get Work Item Payload
    ${vars}=    Get Work Item Variables
    ${files}=    Get Work Item Files    *
