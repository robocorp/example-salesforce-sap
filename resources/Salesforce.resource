*** Settings ***
Resource          common.resource

*** Keywords ***
Salesforce API Authorize
    ${secrets}=    Get Secret    salesforce
    Auth With Token
    ...    username=${secrets}[api_username]
    ...    password=${secrets}[api_password]
    ...    api_token=${secrets}[api_token]

*** Keywords ***
Salesforce List Accounts
    ${columns}    Create List    NAME    ID    ACCOUNT
    ${customer_table}    Create Table    columns=${columns}
    ${account_properties}=    Evaluate    ",".join(${SFDC_ACCOUNT_PROPERTIES})
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
    [Documentation]    This keyword was used to enter test data into Salesforce
    ${table}=    Read Table From Csv    sap_customers.csv
    FOR    ${cus}    IN    @{table}
        ${account}=    Salesforce Query Result As Table    SELECT Id FROM Account WHERE Name = '${cus}[NAME]'
        ${account_len}=    Get Length    ${account}
        ${obj}=    Create Dictionary    Name=${cus}[NAME]    AccountNumber=${cus}[ID]
        IF    ${account_len}==1
        Upsert Salesforce Object    Account    ${account}[0][0]    ${obj}
        ELSE IF    ${account_len}==0
        Create Salesforce Object    Account    ${obj}
        END
    END

*** Keywords ***
Salesforce describe table
    [Documentation]    Can be used to describe SFDC table fields
    [Arguments]    ${table}
    ${tab}=    Describe Salesforce Object    ${table}
    Log Many    ${tab}

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
Salesforce Account Screenshots
    ${secrets}=    Get Secret    salesforce
    Open Available Browser    ${secrets}[website]?source=lex    user_agent=${USER_AGENT}
    Browser.Input Text    id:username    ${secrets}[web_username]
    Browser.Input Password    id:password    ${secrets}[web_password]
    Browser.Click Element    id:Login
    Sleep    10s
    Desktop.Press Keys    esc
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
    ${template}=    Get File    ${OUTPUT_DIR}${/}sfdc_account.template
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
        HTML To PDF    ${document}    ${OUTPUT_DIR}${/}sfdc_account_${ac}[AccountNumber].pdf
    END

*** Keywords ***
Salesforce Create or Modify Accounts
    [Arguments]    ${customers}
    FOR    ${cus}    IN    @{customers}
        ${account}=    Salesforce Query Result As Table    SELECT Id FROM Account WHERE AccountNumber = '${cus}[id]'
        ${account_len}=    Get Length    ${account}
        ${obj}=    Create Dictionary    Name=${cus}[name]    AccountNumber=${cus}[id]
        IF    ${account_len}==1
        Upsert Salesforce Object    Account    ${account}[0][0]    ${obj}
        ELSE IF    ${account_len}==0
        Create Salesforce Object    Account    ${obj}
        END
    END
