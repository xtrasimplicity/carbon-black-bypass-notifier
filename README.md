# Carbon Black Device Bypass Status Notifier
_Notifies you when devices are in bypass mode._

## Usage
1. Create an API account in Carbon Black with `READ` *only* access to a device's info.
  - Go to Settings > API Access > Access Levels
  - Create a new Access Level
  - Tick "READ" next to "Device > General Information > Device"
  - Click API Keys
  - Click Add API Key
  - Enter the details
  - Choose "Custom" under "Access Level Type"
  - Select the Access Level you just created.
  - Click Save.
  - Copy these API keys to a safe place, and use them in the next step.
2. Update the config at the top of the `.ps1` file.
