// seedjob.groovy

// create an array with pipeline names
pipelines = ["Example Job"]

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
          - name: maven
            image: busybox:stable
            command:
            - cat
            tty: true
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
    stage('Clone') {
      steps {
        container('maven') {
          sh 'echo "Git cloning the repo"'
        }
      }
    }
    stage('Build') {
      steps {
        container('maven') {
          sh 'echo "Doing a docker build"'
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