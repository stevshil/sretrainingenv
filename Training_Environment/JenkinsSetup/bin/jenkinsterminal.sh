#!/bin/bash

kubectl exec -it $(kubectl get all -n jenkins | grep pod/jenkins | awk '{print $1}' | sed 's,pod/,,') -n jenkins -- bash