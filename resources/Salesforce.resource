*** Settings ***
Resource          common.resource

*** Variables ***
@{ACCOUNT_PROPERTIES}    Id
...               Name
...               AccountNumber
...               BillingAddress
...               BillingStreet
...               BillingCity
...               BillingState
...               ShippingStreet

*** Keywords ***
Salesforce API Authorize
    ${secrets}=    Get Secret    salesforce
    Auth With Token
    ...    username=${secrets}[USERNAME]
    ...    password=${secrets}[PASSWORD]
    ...    api_token=${secrets}[API_TOKEN]

*** Keywords ***
Salesforce List Accounts
    ${columns}    Create List    NAME    ID    ACCOUNT
    ${customer_table}    Create Table    columns=${columns}
    ${account_properties}=    Evaluate    ",".join(${ACCOUNT_PROPERTIES})
    ${accounts}=    Salesforce Query Result As Table    SELECT ${account_properties} FROM account
    FOR    ${ac}    IN    @{accounts}
        ${row}=    Create Dictionary    NAME=${ac}[Name]    ID=${ac}[Id]    ACCOUNT=${ac}[AccountNumber]
        Add Table Row    ${customer_table}    ${row}
    END
    Write Table To Csv    ${customer_table}    salesforce_customers.csv
    Add Work Item file    salesforce_customers.csv
    Save Work Item
    [Return]    ${accounts}

*** Keywords ***
Salesforce Add or Update Accounts
    # Retrieve file with assistant ?
    ${table}=    Read Table From Csv    sap_customers.csv
    FOR    ${cus}    IN    @{table}
        ${account}=    Salesforce Query Result As Table    SELECT Id FROM Account WHERE Name = '${cus}[NAME]'
        ${account_len}=    Get Length    ${account}
        #${tab}=    Describe Salesforce Object    Account
        #Log Many    ${tab}
        ${obj}=    Create Dictionary    Name=${cus}[NAME]    AccountNumber=${cus}[ID]
        Run Keyword If    ${account_len}==1    Upsert Salesforce Object    Account    ${account}[0][0]    ${obj}
        Run Keyword If    ${account_len}==0    Create Salesforce Object    Account    ${obj}
    END

*** Keywords ***
Salesforce Add Product Orders For Account
    [Arguments]    ${opportunity_name}    ${order_file}=${CURDIR}${/}orders.csv
    ${orders}=    Read Table From CSV    ${order_file}    header=True
    FOR    ${order}    IN    @{orders}
        ${result1}=    Set Account    account_name=${order}[account]
        ${order_id}=    Get Opportunity Id    ${opportunity_name}
        ${result2}=    Add Product Into Opportunity
        ...    product_name=${order}[product]
        ...    quantity=${order}[quantity]
        ...    opportunity_id=${order_id}
    END

*** Keywords ***
Executing dataloader
    [Arguments]    ${orders}
    ${status}=    Execute Dataloader Insert    ${orders}    mapping    Tilaus__c
    ${successes}=    Get Dataloader Success Table
    ${errors}=    Get Dataloader Error Table

*** Keywords ***
Salesforce Account Screenshots
    # https://trailblazers.salesforce.com/answers?id=90630000000glBgAAI
    ${secrets}=    Get Secret    salesforce
    Open Available Browser    ${secrets}[WEBSITE]?source=lex    user_agent=${USER_AGENT}
    Browser.Input Text    id:username    ${secrets}[WEB_USERNAME]
    Browser.Input Password    id:password    ${secrets}[WEB_PASSWORD]
    Browser.Click Element    id:Login
    #${code}=    Get verification code from Email
    #Browser.Input Text    id:emc    ${code}
    #Browser.Click Element    id:save
    Sleep    10s
    Desktop.Press Keys    esc
    #Browser.Go To    https://eu31.lightning.force.com/lightning/o/Account/list?filterName=Recent
    ${table}=    Read Table From Csv    salesforce_customers.csv
    FOR    ${cus}    IN    @{table}
        Browser.Go To    https://eu31.salesforce.com/${cus}[ID]?source=lex
        Wait Until Element Is Visible    css:table.detailList
        Capture Element Screenshot    css:table.detailList    sfdc_account_${cus}[ACCOUNT].png
    END
    [Teardown]    Close All Browsers

*** Keywords ***
Salesforce Account Screenshots With API
    [Arguments]    ${accounts}
    #${tab}=    Describe Salesforce Object    Account
    #Log Many    ${tab}
    ${template}=    Get File    ${CURDIR}${/}sfdc_account.template
    FOR    ${ac}    IN    @{accounts}
        Log Many    ${ac}
        ${account_id}=    Set Variable    ${ac}[Id]
        ${account_name}=    Set Variable    ${ac}[Name]
        ${account_number}=    Set Variable    ${ac}[AccountNumber]
        ${billing_street}=    Set Variable    ${ac}[BillingStreet]
        ${shipping_street}=    Set Variable    ${ac}[ShippingStreet]
        ${billing_city}=    Set Variable    ${ac}[BillingCity]
        ${billing_state}=    Set Variable    ${ac}[BillingState]
        ${timestamp}=    Get Time
        ${document}=    Replace Variables    ${template}
        HTML To PDF    ${document}    ${EXECDIR}${/}output${/}sfdc_account_${ac}[AccountNumber].pdf
    END
