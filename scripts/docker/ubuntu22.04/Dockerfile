# Create Ubuntu 24.04 image
FROM ubuntu:22.04

ARG build_dir
ENV test $build_dir
RUN echo "### " $build_dir
ENV DISPLAY :0
#ENV LIBVA_DRIVER_NAME i965
ENV LIBVA_DRIVER_NAME iHD
ENV LIBVA_DRIVERS_PATH /usr/lib/x86_64-linux-gnu/dri
ENV XDG_RUNTIME_DIR=/tmp
# Setup QT Debugging
ENV QT_DEBUG_PLUGINS=1
# Add /share as a directory in the container
RUN apt-get update
RUN apt-get install vainfo -y
# Copy to the working directory.
COPY *.deb /.
RUN apt-get install ./*.deb -y
