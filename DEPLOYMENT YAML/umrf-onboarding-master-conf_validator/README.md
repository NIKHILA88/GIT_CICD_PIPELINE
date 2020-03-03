Splunk Conf File Validator

Before Running
In order to run this code, you must have python installed. The code is validated to work with python 2.7 on the RedHat Linux 7.6 (RHEL 7) OS.
The following should not be necessary, but in case the script does not run properly, this is the first place to troubleshoot.

The pytz module required to run the script may not come preinstalled. You can check if it is installed by running:
pydoc modules | grep pytz
If you see pytz on the screen or a line similar to the following then pytz is installed:
abc                 grp                 pytz                uuid
If it is not installed, you can install it by running:
sudo yum install pytz


Usage
First, make sure that you have your files on the host (see the Putting and Getting Files section of the general README)
and the you are logged into the host (see the Accessing the Sandbox section of the general README).

Run python validate_confs.py [inputs file name] [props file name] > validation.log

Note: You will likely need to specify the path to the python script, the inputs and props, and/or the validation.log file depending on where you run it from.
To run from the conf directory of an app, the following should work:
python ../../conf_validator/validate_confs.py inputs.conf props.conf > ../docs/validation.log

Note: The inputs and props files must be given in order (with inputs first)
Another note: The program will still run if you don't include the > validation.log part, but that part is needed to create a log file to validate you conf files.

To view the messages output by the program, type cat validation.log

To get the log off of the sandbox into VDI, see the Putting and Getting Files section of the general README

Important: When submitting your conf files to be deployed, you must include the log file that is output from the program as objective proof that your conf files meet some basic standards.
If your conf files mess up due to one of these common errors, you will be held accountable.

Reading the Log
There are several different types of messages you may see in the logs:

INFO -- just for your information
WARN -- there is not neccessarily an error, but you should be careful
ERROR -- there is something wrong with your files


Functionality
This program checks the conf files for the following common mistakes:

Missing brackets in the monitor/sourcetype lines in the inputs/props files
Misspelled or missing monitor:// command in inputs file or too few /'s (should have monitor:/// with the third / being the beginning of the path)
Missing fedex: convention in sourcetype names
Sourcetypes in the inputs that are not defined in the props file
Other standard fields in inputs files missing or misspelled:


index= (should not have any -'s, :'s, or .'s)

sourcetype= (should not have any _'s, -'s, or .'s)
disabled=false


Other standard fields in props files missing or misspelled:


SHOULD_LINEMERGE=false


TRUNCATE=999999


LINE_BREAKER=([\r\n]+)...


MAX_TIMESTAMP_LOOKAHEAD=


TIME_FORMAT= and TIME_PREFIX= or DATETIME_CONFIG=
Note: An error will be output if the standard fields are not present. A warning will be output if a field doesn't match any of these or:


Inputs: whitelist=


Props: FIELD_HEADER_REGEX=
