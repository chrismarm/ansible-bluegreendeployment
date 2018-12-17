### Blue/green deployment

In this sample project we aim to show how to perform a blue/green deployment of a simple containerized application, in our case, a web server serving some static content. The process is orchestrated by `Ansible` as we want to show some interesting features and modules like the `docker_container` module that allows to integrate some of the most useful Docker commands seamlessly in an Ansible Playbook. This playbook provisions a portable `Vagrant` machine with `Docker`, `etcd` and `confd`. In this environment, a container with an `nginx` server is started with the Ansible Docker module. This server is in charge of redirecting the incoming traffic from port 80 to the right application container.

The deployment is performed by a playbook every time `vagrant provision` is called:
* Docker and docker_container modules are installed (or checked they are present).
* etcd is installed and run (or checked it is present).
* confd is installed (if not already installed). The needed configuration files for confd to work are copied in the Vagrant machine, if they are not already present.
* docker_container Ansible module is used to start a Docker container from a nginx image. In the mounted volume, confd writes a file needed by nginx to redirect traffic to the right address.
    * nginx.conf config file is automatically modified to include the configuration of the redirection file.
* a `bash` script runs doing the following:
    1. Determines the current deployment type, blue or green, and sets the new one. To do so, firstly reads from etcd the state of last successful deployment (color and port) and then stores in variables the values for a new one.
    2. Deploys the new version of the app in a new container. In our case, we will simulate that a new image has been built containing the changes in the application code. To do so, it calls Docker to run a nginx container and bind its port 80 to a fixed port based on deployment color (9001/blue, 9002/green). Once the container is up, the script changes the content of the served static content, customized with information about the container and the deployment, as if it was the new application code.
    3. Some tests are run to check the new application is working properly and that the container is healthy. In our case, we curl the new content from the port 80 of the new container IP directly. If it is equals to the expected content, then the tests are OK and deployment goes on.
    4. Deployment current state (color and port) is stored in etcd. confd is called to make changes taking into account the new state in etcd, that is, writing the new port in the redirection file for the new deployment color. From now on, new  requests will be redirected to the new deployed container through the new port.
    5. Once the new application has been deployed, tested and activated, the old container can be removed

After every call to provisioning, we can call `VagrantIP:8000` and check that the shown content belongs to the new application running, that is, alternatively blue or green deployments. Host port 8000 is forwarded to Vagrant guest port 80. Nginx container is mapped 80:80 from Vagrant[Docker]. Application containers are mapped 9001/9002:80 (they listen on containerIP:80) from Vagrant[Docker], so their content is accesible in `VagrantIP:9001/9002` where nginx redirects requests.