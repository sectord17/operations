#!/usr/bin/env bash

PROJECT_USER="sectord17"

PROJECT="$1"
BUILD_NAME="lastSuccessfulBuild"
SECTORD17_PATH="/home/sectord17"

PROJECT_PATH=""
BUILDS_PATH=""
SYSTEMCTL_SERVICE=""

case "${PROJECT}" in
  "server-master")
    PROJECT_PATH="${SECTORD17_PATH}/server-master"
    BUILDS_PATH="~/jobs/master/builds"
    SYSTEMCTL_SERVICE="sectord17-master.service"
    ;;

  "server-slave")
    PROJECT_PATH="${SECTORD17_PATH}/server-slave"
    BUILDS_PATH="~/jobs/slave/builds"
    SYSTEMCTL_SERVICE="sectord17-slave.service"
    ;;

  "server-game")
    PROJECT_PATH="${SECTORD17_PATH}/server-game"
    BUILDS_PATH="~/jobs/game/builds"
    SYSTEMCTL_SERVICE=""
    ;;

  *)
    echo "[ERROR] Allowed projects: server-master, server-slave, server-game"
    exit 1
    ;;
esac

# Set custom build
if [ ! -z "$2" ]; then
  BUILD_NAME="$2"
  echo "[INFO] Deploying build [${BUILD_NAME}]"
fi

# Download project files
ARCHIVE_PATH="${SECTORD17_PATH}/archive-${PROJECT}.zip"
ARCHIVE_REMOTE_PATH="${BUILDS_PATH}/${BUILD_NAME}/archive.zip"

scp jenkins@localhost:"${ARCHIVE_REMOTE_PATH}" "${ARCHIVE_PATH}"
if [ ! $? -eq 0 ]; then
  echo "[ERROR] Failed downloading project archive"
  exit 1
fi

### Start deploy

# Make before instance down
if [[ ! -z ${SYSTEMCTL_SERVICE} ]]; then
  systemctl stop "${SYSTEMCTL_SERVICE}"
fi

BEFORE_DEPLOY_SCRIPT="${PROJECT_PATH}/etc/before-deploy.sh"
if [ -e "${BEFORE_DEPLOY_SCRIPT}" ]; then
  echo "[INFO] Run before deploy script"
  sudo -u "${PROJECT_USER}" "${BEFORE_DEPLOY_SCRIPT}"
fi

if [ -e "${PROJECT_PATH}" ]; then
  echo "[INFO] Remove old project directory"
  rm -Rf "${PROJECT_PATH}"
fi

unzip -q "${ARCHIVE_PATH}" -d "${PROJECT_PATH}"
rm -f "${ARCHIVE_PATH}"
chown -R "${PROJECT_USER}":"${PROJECT_USER}" "${PROJECT_PATH}"

# Make new instance up
cd "${PROJECT_PATH}"
chmod a+x "${PROJECT_PATH}"/etc/*.sh

AFTER_DEPLOY_SCRIPT="${PROJECT_PATH}/etc/after-deploy.sh"
if [ -e "${AFTER_DEPLOY_SCRIPT}" ]; then
  echo "[INFO] Run after deploy script"
  sudo -u "${PROJECT_USER}" "${AFTER_DEPLOY_SCRIPT}"
fi

if [[ ! -z ${SYSTEMCTL_SERVICE} ]]; then
  systemctl start "${SYSTEMCTL_SERVICE}"
fi

echo "[INFO] New version has been successfully deployed"
