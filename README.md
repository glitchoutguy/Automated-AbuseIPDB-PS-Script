Script that takes the output of netstat and checks the established connections against AbuseIPDB

To use the script, navigate to the abuseipdb website, sign in and create your own API key:

https://www.abuseipdb.com/account/api

After placing your personal API key in the script, it is ready to run.


NOTE:
You may need to adjust your powershell execution policy settings to run the script.

Run either of these commands to do so:

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

OR

Set-ExecutionPolicy -ExecutionPolicy Unrestricted


For security reasons, I recommend setting the execution policy to RemoteSigned.
