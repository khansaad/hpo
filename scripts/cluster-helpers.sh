#!/bin/bash
#
# Copyright (c) 2020, 2022 Red Hat, IBM Corporation and others.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Resolve Container runtime
function resolve_container_runtime() {
	IFS='=' read -r -a dockerDeamonState <<< $(systemctl show --property ActiveState docker)
	[[ "${dockerDeamonState[1]}" == "inactive" ]] && CONTAINER_RUNTIME="podman"
	if ! command -v podman &> /dev/null; then
	    echo "No Container Runtime available: Docker daemon is not running and podman command could not be found"
	    exit 1
	fi
}

# Check error code from last command, exit on error
function check_err() {
	err=$?
	if [ ${err} -ne 0 ]; then
		echo "$*"
		exit -1
	fi
}

###############################  v Docker v #################################

function docker_start() {
	
	echo
	echo "###   Starting HPO on Docker"
	echo

	${CONTAINER_RUNTIME} run -d --name hpo_docker_container -p 8085:8085 ${HPO_CONTAINER_IMAGE} >/dev/null 2>&1
	check_err "Unexpected error occured. Service Stopped!"

	echo
	echo "### HPO Docker Service started successfully"
	echo

	sleep 1
	${CONTAINER_RUNTIME} logs hpo_docker_container
	echo
}

function docker_terminate() {

	echo
	echo "###   Removing HPO Docker Container"
	echo

	${CONTAINER_RUNTIME} rm -f  hpo_docker_container >/dev/null 2>&1
	check_err "Failed to stop hpo_docker_container!"

	echo
	echo "###   Successfully Terminated"
	echo

}

###############################  v Native v #################################


function native_start() {
	echo
	echo "###   Installing HPO as a native App"
	echo

	echo
	echo "### Installing dependencies.........."
	echo
	python3 -m pip install -r requirements.txt

	echo
	echo "### Starting the service..."
	echo

	python3 src/service.py
}

function native_terminate() {

	echo
	echo -n "###   Stopping HPO Service"
	echo
		
	echo
	echo "### Press Ctrl-C in the HPO terminal to stop the service"
	echo

}

###############################  v MiniKube v #################################

function minikube_first() {

	kubectl_cmd="kubectl -n ${hpo_ns}"
	echo "Info: One time setup - Create a service account to deploy hpo"
	
	${kubectl_cmd} apply -f ${HPO_SA_MANIFEST}
	check_err "Error: Failed to create service account and RBAC"

	${kubectl_cmd} apply -f ${HPO_ROLE_MANIFEST}
	check_err "Error: Failed to create role"

	sed -e "s|{{ HPO_NAMESPACE }}|${hpo_ns}|" ${HPO_RB_MANIFEST_TEMPLATE} > ${HPO_RB_MANIFEST}
	${kubectl_cmd} apply -f ${HPO_RB_MANIFEST}
	check_err "Error: Failed to create role binding"
}

# You can deploy using kubectl
function minikube_deploy() {
	echo
	echo "Creating environment variable in minikube cluster using configMap"
	${kubectl_cmd} apply -f ${HPO_CONFIGMAPS}/${cluster_type}-config.yaml
    
    # TODO: complete the script

}

function minikube_start() {
	echo
	echo "###   Installing hpo for minikube"
	echo

	# If hpo_ns was not set by the user
	if [ -z "$hpo_ns" ]; then
		hpo_ns="monitoring"
	fi

	minikube_first
	minikube_deploy
}
