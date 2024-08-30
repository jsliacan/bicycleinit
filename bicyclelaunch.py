import os
import logging
import lidar

from datetime import datetime

log_file = "bicycleinit.log"
log_level = logging.DEBUG
date_format = '%Y-%m-%d %H:%M:%S'
logging.basicConfig(filename=log_file, encoding='utf-8', level=log_level, format='%(asctime)s %(message)s', datefmt=date_format) 
log = logging.getLogger(__name__)

# Add a blank line to the log file
log.info("*"*10 + " Started " + "*"*10)

# Add the script name to the log file
log.info("Running " + str(os.path.abspath(__file__)))

log.info("Running " + str(os.path.abspath("lidar.py")))

# stream lidar data to stdout
lidar.streamLidar(5, log, "lidar.csv")

# close log
log.info("*"*10 + " Finished " + "*"*10)
