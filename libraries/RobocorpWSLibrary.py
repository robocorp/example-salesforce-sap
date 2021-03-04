import copy
import json
import requests
from RPA.Cloud.Google import Google
from RPA.Robocloud.Secrets import Secrets
from RPA.Excel.Files import Files
from RPA.Tables import Tables


class RobocorpWSLibrary:
    def __init__(self):
        self._set_request()

    def _set_request(self):
        secrets = Secrets().get_secret("cloud_api")
        self._api_url = f"https://api.eu1.robocorp.com/process-v1/workspaces/{secrets['workspace_id']}"
        self._api_headers = {
            "accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": f"RC-WSKEY {secrets['key']}",
        }
        self._processes = {
            "compare": secrets["compare_process_id"],
            "fix_sfdc_name": secrets["fix_sfdc_name_process_id"],
            "add_sap_account": secrets["add_sap_account_process_id"],
        }

    def ws_list_processes(self):
        response = requests.get(f"{self._api_url}/pruns", headers=self._api_headers)
        result_json = response.json()
        return result_json

    def ws_get_latest_completed_process_run(self, process_id):
        procs = self.ws_list_processes()
        pid = None
        for p in procs:
            print(p)
            if p["state"] == "COMPL" and p["id"] == process_id:
                pid = p["id"]
        return pid

    def ws_get_latest_robot_run(self):
        process_id = self._processes["compare"]
        self._runs_id = self.ws_get_latest_completed_process_run(process_id)
        req_url = (
            f"{self._api_url}/processes/{process_id}/runs/{self._runs_id}/robotRuns"
        )
        response = requests.get(req_url, headers=self._api_headers)
        result_json = response.json()
        self._robot_runid = result_json[0]["id"]

    def ws_get_run_artifacts(self):
        process_id = self._processes["compare"]
        self.ws_get_latest_robot_run()
        req_url = f"{self._api_url}/processes/{process_id}/runs/{self._runs_id}/robotRuns/{self._robot_runid}/artifacts"
        print("ws_get_run_artifacts: %s" % req_url)
        response = requests.get(req_url, headers=self._api_headers)
        result_json = response.json()
        return result_json

    def ws_get_run_artifact(self, artifact_name):
        process_id = self._processes["compare"]
        artifacts = self.ws_get_run_artifacts()
        for a in artifacts:
            if artifact_name == a["fileName"]:
                req_url = f"{self._api_url}/processes/{process_id}/runs/{self._runs_id}/robotRuns/{self._robot_runid}/artifacts/{a['id']}/{artifact_name}"
                print("ws_get_run_artifact: %s" % req_url)
                response = requests.get(req_url, headers=self._api_headers)
                result_json = response.json()
                response = requests.get(result_json, headers=self._api_headers)
                with open(artifact_name, "wb") as fout:
                    fout.write(response.content)
                return

    def ws_start_fix_process(self, data, original):
        tables = Tables()
        missing = []
        conflicts = []
        updated_table = tables.export_table(original, with_index=True, as_list=False)
        positions = []
        for k in data.keys():
            copyof_orig = copy.deepcopy(original)
            if "missingaccount" in k:
                mid, mname = data[k].split(" - ")
                tables.filter_table_by_column(copyof_orig, "Account Id", "==", mid)
                row = tables.get_table_row(copyof_orig, 0)
                missing.append({"id": mid, "name": row["Name in SFDC"]})
                missing_position = updated_table["Account Id"].index(mid)
                updated_table["Account In SAP"][missing_position] = "TRUE"
            elif "nameerror" in k:
                mid, mname = data[k].split(" - ")
                tables.filter_table_by_column(copyof_orig, "Account Id", "==", mid)
                row = tables.get_table_row(copyof_orig, 0)
                conflicts.append({"id": mid, "name": row["Name in SAP"]})
                name_position = updated_table["Account Id"].index(mid)
                updated_table["Name OK in SFDC"][name_position] = "TRUE"

        print("Missing: %s" % missing)
        print("Conflicts: %s" % conflicts)
        print("Original: %s" % original)
        print("Updated_table: %s" % updated_table)
        print("Positions: %s" % positions)
        if conflicts:
            self.ws_run_process("fix_sfdc_name", conflicts)
        if missing:
            self.ws_run_process("add_sap_account", missing)
        excel = Files()
        google = Google()

        google.set_robocloud_vault(
            vault_name="googlecloud", vault_secret_key="credentials"
        )
        google.init_drive_client(use_robocloud_vault=True)
        del updated_table["index"]
        excel.create_workbook("compare_sfdc_to_sap.xlsx")
        excel.append_rows_to_worksheet(updated_table, header=True)
        excel.save_workbook()
        google.drive_upload_file(
            "compare_sfdc_to_sap.xlsx", "aligntech", overwrite=True
        )
        # Drive Upload File    compare_sfdc_to_sap.xlsx    aligntech    overwrite=True

    def ws_run_process(self, process_name, data):
        process_id = self._processes[process_name]
        jsondata = {"variables": data}
        response = requests.post(
            f"{self._api_url}/processes/{process_id}/runs",
            headers=self._api_headers,
            data=json.dumps(jsondata),
        )
        result_json = response.json()
        print(result_json)


if __name__ == "__main__":
    lib = RobocorpWSLibrary()
    # print(lib.ws_get_run_artifact("sap-screenshot_4.jpg"))
    print(
        lib.ws_get_latest_completed_process_run("9ae933eb-d237-4ede-a677-d9325888a0ea")
    )
