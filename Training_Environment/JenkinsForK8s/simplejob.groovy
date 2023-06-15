// seedjob.groovy

// create an array with pipeline names
pipelines = ["Simple Job"]

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