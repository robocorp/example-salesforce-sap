*** Settings ***
Resource          common.resource

*** Keywords ***
Open SAP Logon 760
    Windows.Open Executable    ${EXE_LOGON}    ${TITLE_LOGON}

*** Keywords ***
Open SAP Logon Pad
    Windows.Open Executable    ${EXE_PAD}    ${TITLE_PAD}

*** Keywords ***
SAP Gui Login
    Disable Screenshots On Error
    Open SAP Logon Pad
    Connect To Session
    ${secrets}=    Get Secret    sap_ides
    SAP.Open Connection    ${secrets}[connection]
    SAP.Input Text    ${FIELD_CLIENT}    ${secrets}[client]
    SAP.Input Text    ${FIELD_USER}    ${secrets}[user]
    SAP.Input Password    ${FIELD_PASSWORD}    ${secrets}[password]
    SAP.Send Vkey    0

*** Keywords ***
SAP Get List of Customers
    [Documentation]    Gets customers defined with @{CUSTOMERS} variable
    SAP Get Easy Access Window Area
    ${columns}    Create List    NAME    ID
    ${customer_table}    Create Table    columns=${columns}
    FOR    ${CUSTOMER}    IN    @{SAP_CUSTOMERS}
        SAP.Run Transaction    /nxd03
        SAP.Input Text    ${FIELD_XD03_CUSTOMER_ID}    ${CUSTOMER}
        SAP.Send Vkey    0
        ${customer_name}=    SAP Get account name
        ${row}=    Create Dictionary    NAME=${customer_name}    ID=${CUSTOMER}
        Add Table Row    ${customer_table}    ${row}
        Run Keyword Unless    "${windowarea}"=="${NONE}"    Desktop.Take Screenshot    ${OUTPUT_DIR}${/}sap_account_${CUSTOMER}.png    ${windowarea}
    END
    Write Table To Csv    ${customer_table}    ${SALESFORCE_CSV}
    Add Work Item file    ${SALESFORCE_CSV}
    Save Work Item
    Remove File    ${SALESFORCE_CSV}

*** Keywords ***
SAP Get Easy Access Window Area
    ${wins}=    Get Window List
    Set Task Variable    ${windowarea}    ${NONE}
    FOR    ${win}    IN    @{WINS}
        IF    "${win}[title]"=="SAP Easy Access"
            Set Window Area    ${win}[rectangle]
        END
        Exit For Loop If    "${win}[title]"=="SAP Easy Access"
    END

*** Keywords ***
SAP Get account name
    ${customer_name}=    SAP.Get Value    ${FIELD_ACCOUNT_NAME}
    [Return]    ${customer_name}

*** Keywords ***
SAP Compare Against Salesforce Accounts
    SAP Get Easy Access Window Area
    ${columns}=    Create List    Account Id    Name in SFDC    Name in SAP    Account In SAP    Name OK in SFDC
    ${comptable}=    Create Table    columns=${columns}
    ${salesforce_file}=    Get work item file    salesforce_customers.csv
    ${table}=    Read Table From Csv    ${salesforce_file}
    Remove File    salesforce_customers.csv
    FOR    ${cus}    IN    @{table}
        Log Many    ${table}
        SAP.Run Transaction    /nxd03
        SAP.Input Text    ${FIELD_XD03_CUSTOMER_ID}    ${cus}[ACCOUNT]
        SAP.Send Vkey    0
        ${status}    ${customer_name}=    Run Keyword And Ignore Error    SAP Get account name
        ${exists_ok}=    Set Variable If    "${status}"=="PASS"    TRUE    FALSE
        ${account_name_diff}=    Set Variable If    "${customer_name}"=="${cus}[NAME]"    TRUE    FALSE
        ${contains_error}    Set Variable If    "ValueError: Cannot find element" in "${customer_name}"    TRUE    ${customer_name}
        ${name_in_sap}    Set Variable If    "ValueError: Cannot find element" in "${customer_name}"    ${EMPTY}    ${customer_name}
        ${account_name_diff}=    Set Variable If    "${contains_error}"=="TRUE" or "${account_name_diff}"=="TRUE"    ${account_name_diff}    ${account_name_diff} (${customer_name})
        ${row}=    Create Dictionary
        ...    Account Id=${cus}[ACCOUNT]
        ...    Name in SFDC=${cus}[NAME]
        ...    Name in SAP=${name_in_sap}
        ...    Account In SAP=${exists_ok}
        ...    Name OK in SFDC=${account_name_diff}
        Add Table Row    ${comptable}    ${row}
        IF    "${windowarea}"!="${NONE}"
            Desktop.Take Screenshot    ${OUTPUT_DIR}${/}sap_account_${cus}[ACCOUNT].png    ${windowarea}
        END
    END
    Write Table To Csv    ${comptable}    ${OUTPUT_DIR}${/}compare_sfdc_to_sap.csv
    Create Workbook    ${COMPARISON_EXCEL}
    Append Rows To Worksheet    ${comptable}    header=True
    Save Workbook
    Drive Upload File    ${COMPARISON_EXCEL}    ${GOOGLE_DRIVE_SYNC_FOLDER}    overwrite=True

*** Keywords ***
SAP Graceful Exit
    Connect To Session
    Run Keyword And Ignore Error    SAP.Send VKey    ALT + F4
    Run Keyword And Ignore Error    SAP.Send VKey    ALT + F4
    Run Keyword And Ignore Error    SAP.Send VKey    0
    Windows.Close All Applications
