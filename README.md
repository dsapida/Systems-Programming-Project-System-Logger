# Systems-Programming Project: System Logger

Assignment programmed by David Sapida and Andre Stillo (Add GitLink Here) 

Program Objectives
- Check if a specified user was online every second.
- Appends information to a log file (text file) with a timestamp if either 2 conditions are meet
    1. Specified user has not been online in an hour
    2. Specified user is online
- If specified user is online, get the list of user's processes and append all the information into the log file every second that they are online
- Checking to see if user interacts with a target file (which can be a file you can set, in this case it's a file called MSU-SECRETS)
- Keep script running in tracking user activity or online/offline status and appending information to log file.
- Remove duplicate entries in the log file to keep every log entry unique
- Terminate program if user logs off and the log file has the interaction with the specified file logged.
