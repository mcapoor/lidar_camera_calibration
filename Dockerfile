FROM ros:noetic-ros-base

# Env setup
ENV SHELL=/bin/bash
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

ENV ROS_TARGET=noetic

# Install system dependencies
RUN apt-get update && apt-get install -y \
    locales \
    curl \
    git \
    apt-utils \ 
    software-properties-common \
    && locale-gen en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Install build dependencies
RUN apt-get update -yq && \
    apt-get install -yq --no-install-recommends \
    gcc \
    g++ \ 
    nano \
    python3-rosdep \ 
    python3-wstool \
    python3-pip \
    python3-rosinstall-generator \ 
    python3-vcstool \  
    python3-rosinstall \ 
    build-essential \ 
    python3-rospkg \ 
    python3-catkin-pkg \ 
    python3-catkin-tools \ 
    python3-colcon-core \ 
    python3-colcon-cmake

# Install SPOT SDK dependencies
RUN pip3 install bosdyn-client bosdyn-mission bosdyn-api bosdyn-core 

# Install lidar-camera-calibration package dependencies
RUN apt-get install -yq --no-install-recommends \
    ros-${ROS_TARGET}-cv-bridge \ 
    ros-${ROS_TARGET}-image-transport \
    ros-${ROS_TARGET}-nodelet-core \
    ros-${ROS_TARGET}-velodyne-pcl \ 
    ros-${ROS_TARGET}-image-common \
    ros-${ROS_TARGET}-aruco-msgs \
    ros-${ROS_TARGET}-aruco-ros \
    ros-${ROS_TARGET}-aruco \
    ros-${ROS_TARGET}-image-geometry \
    ros-${ROS_TARGET}-velodyne-msgs \
    ros-${ROS_TARGET}-velodyne-pointcloud \ 
    ros-${ROS_TARGET}-rviz \
    ros-${ROS_TARGET}-rviz-visual-tools \
    ros-${ROS_TARGET}-xacro

# ROS doesn't recognize the docker shells as terminals so force colored output
ENV RCUTILS_COLORIZED_OUTPUT=1

RUN rm -rf /var/lib/apt/lists/*
RUN rm /etc/ros/rosdep/sources.list.d/20-default.list

RUN source /ros_entrypoint.sh

# Initialize rosdep
RUN rosdep init && rosdep update

# Set up lidar workspace
WORKDIR /catkin_ws/src

ADD lidar_camera_calibration /catkin_ws/src/lidar_camera_calibration

RUN mv /catkin_ws/src/lidar_camera_calibration/dependencies/aruco_ros /catkin_ws/src/aruco_ros
RUN mv /catkin_ws/src/lidar_camera_calibration/dependencies/aruco_mapping /catkin_ws/src/aruco_mapping/

# Build the lidar_camera_calibration package
WORKDIR /catkin_ws

RUN rosdep install --from-paths src --ignore-src -r -y
RUN source /ros_entrypoint.sh && catkin_make -DCATKIN_WHITELIST_PACKAGES="aruco;aruco_ros;aruco_msgs"
RUN source /ros_entrypoint.sh && catkin_make -DCATKIN_WHITELIST_PACKAGES="aruco_mapping;lidar_camera_calibration"
RUN source /ros_entrypoint.sh && catkin_make -DCATKIN_WHITELIST_PACKAGES=""