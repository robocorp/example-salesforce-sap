import copy
import json
import requests
from RPA.Cloud.Google import Google
from RPA.Robocorp.Vault import Vault
from RPA.Excel.Files import Files
from RPA.Tables import Tables
from resources.variables import (
    COMPARISON_EXCEL,
    GOOGLE_DRIVE_SYNC_FOLDER,
    CONTROL_ROOM_PROCESS_API,
    CONTROL_ROOM_PROCESS_FIX_SFDC,
)


class ControlRoomLibrary:
    def __init__(self):
        self._set_request()

    def _set_request(self):
        secrets = Vault().get_secret("cloud_api")
        self._api_url = f"{CONTROL_ROOM_PROCESS_API}/workspaces/{secrets['workspace_id']}"
        self._api_headers = {
            "accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": f"RC-WSKEY {secrets['process_api_secret_key']}",
        }
        self._processes = {
            "compare": secrets["compare_process_id"],
            "fix_sfdc_name": secrets["fix_sfdc_name_process_id"],
        }

    def control_room_start_fix_process(self, data, original):
        tables = Tables()
        excel = Files()
        google = Google()
        conflicts = []
        updated_table = tables.export_table(
            original, with_index=True, as_list=False)
        for k in data.keys():
            copyof_orig = copy.deepcopy(original)
            if "nameerror" in k:
                mid, _ = data[k].split(" - ")
                tables.filter_table_by_column(
                    copyof_orig, "Account Id", "==", mid)
                row = tables.get_table_row(copyof_orig, 0)
                conflicts.append({"id": mid, "name": row["Name in SAP"]})
                name_position = updated_table["Account Id"].index(mid)
                updated_table["Name OK in SFDC"][name_position] = "TRUE"

        if conflicts:
            self.control_room_run_process(
                CONTROL_ROOM_PROCESS_FIX_SFDC, conflicts)

        google.set_robocorp_vault(
            vault_name="googlecloud", vault_secret_key="credentials"
        )
        google.init_drive(use_robocorp_vault=True)
        del updated_table["index"]
        excel.create_workbook(COMPARISON_EXCEL)
        excel.append_rows_to_worksheet(updated_table, header=True)
        excel.save_workbook()
        google.drive_upload_file(
            COMPARISON_EXCEL, GOOGLE_DRIVE_SYNC_FOLDER, overwrite=True
        )

    def control_room_run_process(self, process_name, data):
        process_id = self._processes[process_name]
        jsondata = {"variables": data}
        response = requests.post(
            f"{self._api_url}/processes/{process_id}/runs",
            headers=self._api_headers,
            data=json.dumps(jsondata),
        )
        result_json = response.json()
        print(result_json)
