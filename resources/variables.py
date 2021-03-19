COMPARISON_EXCEL = "compare_sfdc_to_sap.xlsx"
SALESFORCE_CSV = "sap_customers.csv"
USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.517 Safari/537.36"
GOOGLE_DRIVE_SYNC_FOLDER = "Finance Department"

# Salesforce variables
SFDC_ACCOUNT_PROPERTIES = [
    "Id",
    "Name",
    "AccountNumber",
    "BillingAddress",
    "BillingStreet",
    "BillingCity",
    "BillingState",
    "ShippingStreet",
]

# SAP variables
EXE_PAD = "C:\\Program Files (x86)\\SAP\\FrontEnd\\SAPgui\\saplgpad.exe"
EXE_LOGON = "C:\\Program Files (x86)\\SAP\\FrontEnd\\SAPgui\\saplogon.exe"
TITLE_PAD = "SAP Logon Pad 760"
TITLE_LOGON = "SAP Logon 760"
FIELD_CLIENT = "wnd[0]/usr/txtRSYST-MANDT"
FIELD_USER = "wnd[0]/usr/txtRSYST-BNAME"
FIELD_PASSWORD = "wnd[0]/usr/pwdRSYST-BCODE"
FIELD_TRANSACTION = "wnd[0]/tbar[0]/okcd"
FIELD_XD03_CUSTOMER_ID = "wnd[1]/usr/ctxtRF02D-KUNNR"
FIELD_ACCOUNT_NAME = "wnd[0]/usr/subSUBTAB:SAPLATAB:0100/tabsTABSTRIP100/tabpTAB01/ssubSUBSC:SAPLATAB:0201/subAREA1:SAPMF02D:7111/subADDRESS:SAPLSZA1:0300/subCOUNTRY_SCREEN:SAPLSZA1:0301/txtADDR1_DATA-NAME1"
SAP_CUSTOMERS = [3511, 3691, 3690, 3574, 3512, 3505, 3504]

# Robocloud
ROBOCLOUD_PROCESS_API = "https://api.eu1.robocorp.com/process-v1"
ROBOCLOUD_PROCESS_FIX_SFDC = "fix_sfdc_name"
