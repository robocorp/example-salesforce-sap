# README

## Demo script

1. Read customer account names and IDs in SFDC
2. Check against customer account names and IDs in SAP
3. Create an excel showing the missing customer accounts in SAP
4. Use an assistant with dialogue library to create missing customers to SAP
5. (Extra extra bonus: create an assistant to update SAP customer account names to SFDC

## Restrictions

- The only working way of disabling SFDC verification code when signing in to the SFDC, was to whitelist IP address used to login. This means that login works only from one location at the moment (whitelist can be modified).
