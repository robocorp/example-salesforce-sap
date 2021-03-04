*** Settings ***
Library           Collections
Library           OperatingSystem
Library           String
Library           RPA.Browser.Selenium    WITH NAME    Browser
Library           RPA.Cloud.Google
Library           RPA.Desktop    WITH NAME    Desktop
Library           RPA.Desktop.Windows    WITH NAME    Windows
Library           RPA.Dialogs    WITH NAME    Dialogs
Library           RPA.Email.ImapSmtp
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.Robocloud.Items
Library           RPA.Robocloud.Secrets
Library           RPA.Salesforce
Library           RPA.SAP    WITH NAME    SAP
Library           RPA.Tables
Library           RobocorpWSLibrary
#Library          SapHanaDatabaseLibrary

*** Variables ***
${USER_AGENT}     Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.517 Safari/537.36

*** Keywords ***
Set Window Area
    [Arguments]    ${rect}
    Set Task Variable    ${windowarea}    region:${rect}[0],${rect}[1],${rect}[2],${rect}[3]

*** Keywords ***
Get verification code from Email
    ${secrets}=    Get Secret    email
    Authorize IMAP
    ...    account=${secrets}[username]
    ...    password=${secrets}[password]
    ...    imap_server=${secrets}[server]
    ${emails}    Wait For Message    SUBJECT "Verify your identity in Salesforce"    timeout=60.0
    Run Keyword Unless    ${emails}    Fail    Did not receive verifications message from Salesforce
    FOR    ${email}    IN    @{emails}
        ${lines}=    Split To Lines    ${email}[Body]
        ${code}=    Find text in lines    ${lines}    Verification Code: (\\d+)
        Exit For Loop If    "${code}"!="${NONE}"
    END
    Delete Messages    SUBJECT "Verify your identity in Salesforce"
    [Return]    ${code}

*** Keywords ***
Find text in lines
    [Arguments]    ${lines}    ${regexp}
    ${code}=    Set Variable    ${NONE}
    FOR    ${line}    IN    @{lines}
        ${linestr}    Convert To String    ${line}
        ${status}    ${matches}=    Run Keyword And Ignore Error    Should Match Regexp    ${linestr}    ${regexp}
        Log Many    ${matches}
        ${code}=    Set Variable If    "${status}"=="PASS"    ${matches}[1]    ${NONE}
        Exit For Loop If    "${status}"=="PASS"
    END
    [Return]    ${code}

*** Keywords ***
Google Drive Initialization
    Set Robocloud Vault    vault_name=googlecloud    vault_secret_key=credentials
    Init Drive Client    use_robocloud_vault=True
