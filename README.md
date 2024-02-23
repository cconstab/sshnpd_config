# Scale test rig for sshnpd/atServer

## Set up environment
The aim of this code is to scale up N number of docker containers and be able to login to them with sshnp.

1) Tune the Dockerfile variables to your liking.
    
    a) Change the USERNAME

    b) Change the sshnp image SSHNPD_IMAGE for your architecture

2) Build a docker image with something like:

    `docker build -t scale .`

3) Once the image has been built you can run the image with:

    `docker run -it -v ~/.atsign/keys/@ssh_1_key.atKeys:/home/ubuntu/.atsign/keys/@ssh_1_key.atKeys scale`

To break that down you need to mount the device atSign .atKeys file in the ~/.atsign/keys.<atSign>_key.atKeys file.

The `run -it` is an interactive session so it will give you a prompt which will contain the hostname eg.

    `ubuntu@b51e66a5f60b:~$` 

4) Connect to the container with sshnp

Copy the host name and place it in the `-d` argument of your `sshnp` command, making shure to include the
`-s` to get the `-i` ssh key in the right spot and the `-u` flag with the username. Putting it all together it will look something like this:

`sshnp -f @cconstab -t @ssh_1  -h @rv_am -s  -u ubuntu -i ~/.ssh/id_ed25519 -d e97f3e401edb`

At that point you will be logged into the container! 

## To scale test
This is the simple part just run up as many containers as you like and as each uses the same atSigns and the `-d` flag is set by hostname you can use the same sshnp coammand just change the hostname.

To run a container in the background just use the `-d` flag on the docker command like this:

`docker run -d -v ~/.atsign/keys/@ssh_1_key.atKeys:/home/ubuntu/.atsign/keys/@ssh_1_key.atKeys scale`

You can see the hostname in the first column of `docker ps`

```
% docker ps
CONTAINER ID   IMAGE     COMMAND                   CREATED              STATUS              PORTS     NAMES
f29b74f57771   scale     "/bin/sh -c '\"./star…"   About a minute ago   Up About a minute             frosty_bardeen
```

Then use something like this to login into the container

`sshnp -f @cconstab -t @ssh_1  -h @rv_am -s  -u ubuntu -i ~/.ssh/id_ed25519 -d f29b74f57771`

## Putting this altogether looks like this

[![asciicast](https://asciinema.org/a/YKN91isQPkg0zSybSwMlUIBZh.svg)](https://asciinema.org/a/YKN91isQPkg0zSybSwMlUIBZh)

# A few sample scripts 

Fire off 100 containers

```
CNT=0
while ((CNT<100))
do
((CNT++))
docker run -d -v ~/.atsign/keys/@ssh_1_key.atKeys:/home/ubuntu/.atsign/keys/@ssh_1_key.atKeys scale
done
```

And stop & remove ALL the containers on your machine. Just be careful if you have other things going on !

```
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
```