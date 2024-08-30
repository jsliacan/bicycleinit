"""
    Garmin Lidar-Lite v3 

    Info:
        (Garmin repo) https://github.com/garmin/LIDARLite_RaspberryPi_Library/
        (Lidar-Lite v3 internal register addresses) https://github.com/garmin/LIDARLite_RaspberryPi_Library/blob/master/include/lidarlite_v3.h
        (Adafruit GLLv3 article) https://www.adafruit.com/product/4058#technical-details
        (Good Lidar-Lite lib for python?) https://github.com/Sanderi44/Lidar-Lite
        (Tutorial) https://mobiusstripblog.wordpress.com/2016/12/26/first-blog-post/
"""

import smbus2 as smbus
import datetime, time
import logging
import csv

BUS = 1 # on RPi5, it's bus no.1 - can check with `ls /dev/*i2c*`
ADDRESS = 0x62 # get with `sudo i2cdetect -y 1`
DISTANCE_WRITE_REGISTER = 0x00
DISTANCE_WRITE_VALUE = 0x04
DISTANCE_READ_REGISTER_1 = 0x8f
DISTANCE_READ_REGISTER_2 = 0x10


def writeAndWait(bus, register, value):
    bus.write_byte_data(ADDRESS, register, value);
    time.sleep(0.02) # rest

def readDistAndWait(bus, register):
    reading = bus.read_i2c_block_data(ADDRESS, register, 2)
    time.sleep(0.02)
    return (reading[0] << 8 | reading[1])

def getDistance(bus, distWriteRegister, distWriteValue):
    writeAndWait(bus, distWriteRegister, distWriteValue)
    dist = readDistAndWait(bus, DISTANCE_READ_REGISTER_1)
    return dist

def streamLidar(timeout, logger, csv_data_file):
    """
        timeout - time in seconds (or -1 for infinity)
    """

    try:
        actual_bus = smbus.SMBus(BUS) 
    except IOError:
        logger.error("Error connecting to the i2c device with address " + str(ADDRESS) + " on bus number " + str(BUS))
    start = datetime.datetime.now()
    with open(csv_data_file, "w") as df:
        writer = csv.writer(df, delimiter=",")
        writer.writerows([["date", "time", "distance"]])
        while timeout == -1 or datetime.datetime.now() - start < datetime.timedelta(seconds=timeout):
            try:
                distance = getDistance(actual_bus, DISTANCE_WRITE_REGISTER, DISTANCE_WRITE_VALUE) # in cm
                datestamp, timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f").split(" ")
                writer.writerows([[datestamp, timestamp, distance]])
                logger.info("taken lidar reading")
            except Error:
                logger.error("could not read distance or write to CSV file")


if __name__ == "__main__":

    try:
        actual_bus = smbus.SMBus(BUS) 
    except IOError:
        print("Error connecting to the i2c device with address", ADDRESS, "on bus number", BUS)

    for i in range(200):
        distance = getDistance(actual_bus, DISTANCE_WRITE_REGISTER, DISTANCE_WRITE_VALUE)
        print(distance, "cm")
