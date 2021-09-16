*** Settings ***
Library           Collections
Library           OperatingSystem
Library           String
Library           RPA.Browser.Selenium    WITH NAME    Browser
Library           RPA.Cloud.Google
Library           RPA.Desktop    WITH NAME    Desktop
Library           RPA.Desktop.Windows    WITH NAME    Windows
Library           RPA.Dialogs    WITH NAME    Dialogs
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.Robocorp.WorkItems
Library           RPA.Robocorp.Vault
Library           RPA.Salesforce
Library           RPA.SAP    WITH NAME    SAP
Library           RPA.Tables
Library           ControlRoomLibrary
Variables         variables.py

*** Keywords ***
Set Window Area
    [Arguments]    ${rect}
    Set Task Variable    ${windowarea}    region:${rect}[0],${rect}[1],${rect}[2],${rect}[3]

*** Keywords ***
Find text in lines
    [Arguments]    ${lines}    ${regexp}
    ${code}=    Set Variable    ${NONE}
    FOR    ${line}    IN    @{lines}
        ${linestr}    Convert To String    ${line}
        ${status}    ${matches}=    Run Keyword And Ignore Error    Should Match Regexp    ${linestr}    ${regexp}
        ${code}=    Set Variable If    "${status}"=="PASS"    ${matches}[1]    ${NONE}
        Exit For Loop If    "${status}"=="PASS"
    END
    [Return]    ${code}

*** Keywords ***
Google Drive Initialization
    Set Robocorp Vault    vault_name=googlecloud    vault_secret_key=credentials
    Init Drive    use_robocorp_vault=True

*** Keywords ***
Google Drive Download Specific File
    [Arguments]    ${filename}    ${folder}=${GOOGLE_DRIVE_SYNC_FOLDER}
    ${files}=    Search Drive Files
    ...    query=name contains '${filename}'
    ...    folder_name=${folder}
    IF    len(${files}) == 1
        Download Drive Files    file_dict=${files}[0]
    ELSE
        Fail    Could not find file '${filename}' in folder '${folder}'
    END

*** Keywords ***
Get Comparison Excel from Google Drive
    Google Drive Initialization
    Google Drive Download Specific File    ${COMPARISON_EXCEL}
    Move File    ${COMPARISON_EXCEL}    ${OUTPUT_DIR}${/}
    Open Workbook    ${OUTPUT_DIR}${/}${COMPARISON_EXCEL}
    ${rows}=    Read Worksheet As Table    header=True
    Close Workbook
    [Return]    ${rows}

*** Keywords ***
Create Form For User
    [Arguments]    ${rows}
    ${name_errors}=    Create List
    FOR    ${row}    IN    @{rows}
        ${account_name}=    Replace String    ${row}[Name in SFDC]    ,    ${EMPTY}
        IF    "FALSE" in "${row}[Name OK in SFDC]" and "${row}[Account In SAP]"=="TRUE" and "${row}[Name in SAP]" != "None"
            Append To List
            ...    ${name_errors}
            ...    ${row}[Account Id] - ${account_name} [in SAP -> ${row}[Name in SAP]]
        END
    END
    Add heading    Validate SFDC accounts against SAP
    IF    ${name_errors}
        Add text    Fix account name in SFDC
        FOR    ${index}    ${name}    IN ENUMERATE    @{name_errors}    start=1
            Add Checkbox
            ...    name=nameerror${index}
            ...    label=${name}
        END
    ELSE
        Add text    Nothing to fix. SFDC account names match SAP account names.
    END
    ${response}=    Run dialog
    [Return]    ${response}
