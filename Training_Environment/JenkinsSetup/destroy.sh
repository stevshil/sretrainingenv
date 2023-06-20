#!/bin/bash

kill $(ps -ef | grep tunnel | grep -v grep | awk '{print $2}')
minikube delete