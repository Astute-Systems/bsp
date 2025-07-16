#!/bin/bash -e

rm -rf /opt/AstuteSys

if [ -L /home/${SUDO_USER}/AstuteSys ]; then
   unlink /home/${SUDO_USER}/AstuteSys
fi
