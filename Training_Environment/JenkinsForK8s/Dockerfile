# Taken from
# https://www.digitalocean.com/community/tutorials/how-to-automate-jenkins-setup-with-docker-and-jenkins-configuration-as-code
# https://github.com/jenkinsci/helm-charts/blob/main/charts/jenkins/README.md
FROM jenkins/jenkins:lts
# Stop setup wizard from launching
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
ENV CASC_JENKINS_CONFIG /usercasc/casc.yaml
# Install required plugins
COPY jenkinsplugins.txt /usr/share/jenkins/ref/plugins.txt
COPY seedjob.groovy /usr/share/jenkins/ref/seedjob.groovy
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
# Set up URL
COPY casc.yaml /usercasc/casc.yaml
# Expose Jenkins web UI and JNLP
EXPOSE 8080
EXPOSE 50000
VOLUME /usercasc
