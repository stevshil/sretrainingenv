// seedjob.groovy

// create an array with pipeline names
pipelines = ["Docker Pull Push Job"]

// iterate through the array and call the create_pipeline method
pipelines.each { pipeline ->
    println "Creating pipeline ${pipeline}"
    create_pipeline(pipeline)
}

// a method that creates a basic pipeline with the given parameter name
def create_pipeline(String name) {
    pipelineJob(name) {
        definition {
            cps {
                sandbox(true)
                script("""
// this is an example declarative pipeline that shows a Kubernetes Job to launch a maven container
pipeline {
  agent {
    kubernetes {
      yaml '''
        apiVersion: v1
        kind: Pod
        spec:
          containers:
          - name: docker
            image: docker:latest
            command:
            - cat
            tty: true
            volumeMounts:
             - mountPath: /var/run/docker.sock
               name: docker-sock
          volumes:
          - name: docker-sock
            hostPath:
              path: /var/run/docker.sock
        '''
    }
  }
  stages {
    stage('Registry connecion') {
      steps {
        container('docker') {
          sh '''
            echo "curling registry"
            apk add curl
            curl -k https://registry-int.docker-registry.svc.cluster.local:5000/v2/
            reg=`nslookup registry-int.docker-registry.svc.cluster.local | grep Address | tail -1 | awk '{print \$2}'`
            echo "REGISTRY IP: \$reg"
          '''
        }
      }
    }
    stage('Pull') {
      steps {
        container('docker') {
          sh '''
            echo "Downloading busybox"
            docker pull busybox
          '''
        }
      }
    }
    stage('Tag') {
      steps {
        container('docker') {
          sh '''
            echo "Tagging for private registry"
            # Works if you use cluster-ip for service - agent containers not using DNS
            reg=`nslookup registry-int.docker-registry.svc.cluster.local | grep Address | tail -1 | awk '{print \$2}'`
            docker tag busybox \$reg:5000/busybox:latest
          '''
        }
      }
    }
    stage('Push') {
      steps {
        container('docker') {
          sh '''
            echo "Pushing to private registry"
            reg=`nslookup registry-int.docker-registry.svc.cluster.local | grep Address | tail -1 | awk '{print \$2}'`
            docker push \$reg:5000/busybox:latest
          '''
        }
      }
    }
  }
}

""")
            }
        }
    }
}