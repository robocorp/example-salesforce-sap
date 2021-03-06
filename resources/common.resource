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
Library           RPA.Robocloud.Items
Library           RPA.Robocloud.Secrets
Library           RPA.Salesforce
Library           RPA.SAP    WITH NAME    SAP
Library           RPA.Tables
Library           RobocloudLibrary
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
    Set Robocloud Vault    vault_name=googlecloud    vault_secret_key=credentials
    Init Drive Client    use_robocloud_vault=True

*** Keywords ***
Google Drive Download Specific File
    [Arguments]    ${filename}    ${folder}=${GOOGLE_DRIVE_SYNC_FOLDER}
    ${files}=    Drive Search Files
    ...    query=name contains '${filename}'
    ...    folder_name=${folder}
    IF    len(${files}) == 1
    Drive Download Files    file_dict=${files}[0]
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
    ${name_string}=    Evaluate    ",".join(${name_errors})
    Create Form    Validate SFDC accounts against SAP
    IF    ${name_errors}
    Add Checkbox    label=Fix account name in SFDC
    ...    element_id=nameerror
    ...    options=${name_string}
    ELSE
    Add Text    Nothing to fix. <br><br>SFDC account names match SAP account names.
    END
    &{response}=    Request Response
    [Return]    ${response}
