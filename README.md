# A robot that compares account data between Salesforce and SAP

This robot demonstrates how to get accounts details from [Salesforce](https://www.salesforce.com/) and [SAP](https://www.sap.com/). 

Robot can be used to start process to fix accounts in Salesforce if the Salesforce account data does not match account data in SAP.

## Task descriptions

This robot includes several different tasks and their task descriptions are provided below. The tasks that are started either via Robocorp Cloud or using Robocorp Assistant are **Compare Salesforce and SAP accounts** and **Fix comparison errors**.

### **Task**: `Compare Salesforce and SAP accounts`

- Run type: Unattended using Robocorp Agent (Windows)
- Description: This task will get list of accounts from SFDC using Salesforce API and compares those accounts with SAP account data using SAP GUI interface. Results are stored into Excel file, which is stored into Google Drive.

### **Task**: `Fix comparison errors`

- Run Type: Attended using Robocorp Assistant (Windows/MacOS/Linux)
- Description: This task will download the comparison Excel from Google Drive and creates user dialog, which will prompt user to select accounts to be fixed.

### **Task**: `List accounts from SAP`

- Run Type: Unattended (Windows)
- Description: This task views set of SAP accounts using SAP GUI.

### **Task**: `List accounts from Salesforce`

- Run Type: Unattended (Windows/MacOS/Linux)
- Description: This task gets all Salesforce accounts via Salesforce API and views them on Salesforce site using browser. Screenshot of each account's details are saved into files.

### **Task**: `List accounts from Salesforce (no browser)`

- Run Type: Unattended (Windows/MacOS/Linux)
- Description: This task gets all Salesforce accounts via Salesforce API and saves data from each account into PDF file.

### **Task**: `Create New Accounts to Salesforce`

- Run Type: Unattended (Windows/MacOS/Linux)
- Description: This task reads account data from a CSV file and adds an account (if it does not exist) or updates account data (if account already exists) in Salesforce.

### **Task**: `Fix Account Name in SFDC`

- Run Type: Unattended (Windows/MacOS/Linux)
- Description: This task reads account data from a work item variable and adds an account (if it does not exist) or updates account data (if account already exists) in Salesforce.

## The robot

```robot
*** Settings ***
Documentation     Execution report
Resource          SAP.resource
Resource          Salesforce.resource

*** Tasks ***
Compare Salesforce and SAP accounts
    [Setup]    Google Drive Initialization
    SAP Gui Login
    SAP Compare Against Salesforce Accounts
    [Teardown]    SAP Graceful Exit

Fix comparison errors
    ${rows}=    Get Comparison Excel from Google Drive
    ${response}=    Create Form For User    ${rows}
    Robocloud Start Fix Process    ${response}    ${rows}

List accounts from SAP
    SAP Gui Login
    SAP Get List of Customers
    [Teardown]    SAP Graceful Exit

List accounts from Salesforce
    Salesforce API Authorize
    Salesforce List Accounts
    Salesforce Account Screenshots

List accounts from Salesforce (no browser)
    Salesforce API Authorize
    ${accounts}=    Salesforce List Accounts
    Salesforce Account Screenshots With API    ${accounts}

Create New Accounts to Salesforce
    Salesforce API Authorize
    Salesforce Add or Update Accounts

Fix Account Name in SFDC
    Salesforce API Authorize
    ${vars}=    Get Work Item Variables
    Salesforce Create or Modify Accounts    ${vars}
```

## Libraries

The [`RPA.Cloud.Google`](https://robocorp.com/docs/libraries/rpa-framework/rpa-cloud-google) library handles operations with Google Drive.

The [`RPA.Browser.Selenium`](https://robocorp.com/docs/development-guide/browser/selenium) manages the browser automation duties.

The [`RPA.Tables`](https://robocorp.com/docs/libraries/rpa-framework/rpa-tables) library takes care of saving the data into a CSV file.

The [`RPA.Excel.Files`](https://robocorp.com/docs/libraries/rpa-framework/rpa-excel-files) library takes care of saving the data into a Excel file.

The [`RPA.Desktop`](https://robocorp.com/docs/libraries/rpa-framework/rpa-desktop) library is used to take desktop screenshots.

The [`RPA.Desktop.Windows`](https://robocorp.com/docs/libraries/rpa-framework/rpa-desktop-windows) library handles starting of SAP GUI application.

The [`RPA.SAP`](https://robocorp.com/docs/libraries/rpa-framework/rpa-sap) library manages interactions with SAP GUI interface.

The [`RPA.Salesforce`](https://robocorp.com/docs/libraries/rpa-framework/rpa-salesforce) library handles operations with Salesforce REST API.

The [`RPA.PDF`](https://robocorp.com/docs/libraries/rpa-framework/rpa-pdf) library creates PDFs with account details.

The [`RPA.Dialogs`](https://robocorp.com/docs/libraries/rpa-framework/rpa-dialogs) library manages attended UI interface.

The [`RobocloudLibrary`](https://github.com/robocorp/example-salesforce-sap/blob/master/libraries/RobocloudLibrary.py) custom library is used to manage Robocloud processes via Process API.

Other Robotframework libraries in use are [`Collections`](https://robocorp.com/docs/libraries/built-in/collections),  [`OperatingSystem`](https://robocorp.com/docs/libraries/built-in/operatingsystem) and  [`String`](https://robocorp.com/docs/libraries/built-in/string)
## Configuration

Common variables for the robot are stored in [`variables.py`](https://github.com/robocorp/example-salesforce-sap/blob/master/resources/variables.py) file.

The Google Drive credentials and several other sensitive data has been stored into Robocorp Vault.

> [Learn how to use the Robocorp vault to store secrets](https://robocorp.com/docs/development-guide/variables-and-secrets/vault).

### Create a `vault.json` file for the credentials

Create a new file: `/Users/<username>/vault.json`

```json
{
  "sap_ides": {
    "connection": "SAP-CONNECTION-NAME-STRING",
    "client": "SAP-CONNECTION-CLIENT-ID",
    "user": "SAP-USERNAME",
    "password": "SAP-PASSWORD",
  },
  "salesforce": {
      "website": "URL-TO-SALESFORCE",
      "web_username": "SALESFORCE-USERNAME",
      "web_password": "SALESFORCE-PASSWORD",
      "api_username": "SALESFORCE-API-USERNAME",
      "api_password": "SALESFORCE-API-PASSWORD",
      "api_token": "SALESFORCE-API-TOKEN"
  },
  "cloud_api": {
      "workspace_id": "ROBOCLOUD-WORKSPACE-ID",
      "process_api_secret_key": "PROCESS-API-KEY",
      "compare_process_id": "PROCESS-ID-FOR-COMPARE-PROCESS",
      "fix_sfdc_name_process_id": "PROCESS-ID-FOR-FIX-SFDC-NAME-PROCESS",
  }
}
```

### Create a `items.json` file for the work item variables
Create a new file: `/Users/<username>/items.json`

```json
{
    "1": {
        "1": {
            "variables": {
            }
        }
    }
}
```
### Point `devdata/env.json` to your `vault.json` and `items.json` files

```json
{
  "RPA_SECRET_MANAGER": "RPA.Robocloud.Secrets.FileSecrets",
  "RPA_SECRET_FILE": "/Users/<username>/vault.json",
  "RPA_WORKITEMS_ADAPTER": "RPA.Robocloud.Items.FileAdapter",
  "RPA_WORKITEMS_PATH": "/Users/<username>/items.json",
  "RC_WORKSPACE_ID": 1,
  "RC_WORKITEM_ID": 1
}
```

### Robocorp Cloud vault

Create new secrets with names `sap_ides`, `cloud_api` and `salesforce`. The key-value pairs can be seen above in the `vault.json`.

## I want to learn more!

Visit [Robocorp docs](https://robocorp.com/docs/) to learn more about developing robots to automate your processes!

[Robocorp portal](https://robocorp.com/portal/) contains many example robots with all the source code included.

Follow the [Robocorp YouTube channel](https://www.youtube.com/Robocorp) for automation-related videos.

Visit the [Software Robot Developer forum](https://forum.robocorp.com/) to discuss all-things automation. Ask questions, get answers, share your robots, help others!
