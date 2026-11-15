cmake_minimum_required(VERSION 3.16)

# idf.py and the ESP-IDF extension look for this file in the folder you opened.
# The sources stay in firmware/. Opening the repo and setting the target to esp32s3
# builds the Elecrow CrowPanel Advance 5.0. Another screen is still
# firmware/BUILD.BAT <name>, or -DRADAR_DISPLAY=N (the numbers are in that file).
if(NOT DEFINED RADAR_DISPLAY)
    set(RADAR_DISPLAY 10)
endif()

include(${CMAKE_CURRENT_LIST_DIR}/firmware/CMakeLists.txt)
