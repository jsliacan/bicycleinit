import os
from datetime import datetime

# Log file name
log_file = "bicycleinit.log"

# Function to append data to the log file
def append_to_log(data):
    print(data)
    with open(log_file, "a") as f:
        f.write(data + "\n")

# Add a blank line to the log file
append_to_log("")

# Add the current date and time to the log file
current_datetime = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
append_to_log(current_datetime)

# Add the script name to the log file
script_name = os.path.abspath(__file__)
append_to_log(script_name)

# TODO: Launch all the sensors
