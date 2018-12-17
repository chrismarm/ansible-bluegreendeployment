#!/bin/sh

echo "New color/port calculation"
# Getting the color/port for the deployment, that is, the opposite of the current deployment
BLUE_PORT=9001
GREEN_PORT=9002
CURRENT_COLOR=$(etcdctl get /deployment/color)
if [ "$CURRENT_COLOR" = "" ]; then
  CURRENT_COLOR="green"
fi
if [ "$CURRENT_COLOR" = "blue" ]; then
  PORT=$GREEN_PORT
  COLOR="green"
else
  PORT=$BLUE_PORT
  COLOR="blue"
fi

echo "Stopping and removing existing containers"
# Stopping and removing existing containers for the new deployment color, just in case
set +e
docker stop app1-$COLOR
docker rm app1-$COLOR

echo "Starting deployment $COLOR on port $PORT"
set -e
docker run -d --name app1-$COLOR -p $PORT:80 nginx
# New container IP extraction
CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' app1-$COLOR)
CONTENT="Deployment $COLOR on container $CONTAINER_IP on port $PORT"
# New application code deployment simulation, in our case, just changing published content
docker exec app1-$COLOR /bin/bash -c "echo $CONTENT > /usr/share/nginx/html/index.html"

echo "Testing deployment $COLOR on port $PORT"
# Before changing the redirection URL of nginx and start sending requests to it, we must make sure that the container with new application code works properly
echo "TEST: Expected content: $CONTENT"
TEXT=$(curl -s "http://$CONTAINER_IP:80")
echo "TEST: Actual content: $TEXT"
if [ "$TEXT" = "$CONTENT" ]; then
    echo "Tests passed OK"
else
    echo "Tests FAILED. Deployment was not performed"
    exit 1
fi

echo "Updating deployment info"
# Storing new release information and update nginx to start redirecting traffic to the new deployment
etcdctl set /deployment/color $COLOR
etcdctl set /deployment/port $PORT
confd -onetime -node http://127.0.0.1:2379 -config-file /etc/confd/conf.d/deployment.toml

echo "Stopping old $CURRENT_COLOR deployment"
set +e
docker stop app1-$CURRENT_COLOR
docker rm app1-$CURRENT_COLOR
set -e