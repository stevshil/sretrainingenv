#!/bin/bash

kill $(ps -ef | grep tunnel | awk '{print $2}')
minikube delete