# Install sshnpd at scale

## Notes
Each atSign has a reasonable maximum of 25 devices that it can manage so keep that in mind as you use this script to rollout devices.

## Set up environment
Each atSign has its own set of keys that are "cut" with at_activate. This will cut the keys for the atSign an place them in `~/.atsign/keys`. But each machine you want run sshnpd on also needs these keys so we need to have a way to get them to each device.
It is possible to ssh/scp them but that becomes very cumbersome at scale. Instead we encrypt the keys with AES256 and place them on a webserver. When the install script is run it knows bot the URL and the encryption password and can pull the atKeys file to the right place.

The steps are to get the atKeys file as normal using at_activate then encrypt them using a command like this:

```
mkdir enckeys
cd enckeys
openssl enc -aes-256-cbc -pbkdf2 -iter 1000000 -salt -in ~/.atsign/keys/@ssh_1_key.atKeys -out @ssh_1_key.atKeys.aes
```
This command will ask you for a passord which you will put in the `install.sh` file as `ATKEY_PASSWORD`.


You can then set up a simple http (the file is encrypted) server to serve the keys, with for example a python single line of code.

`python3 -m http.server 8080 --bind 0`

At this point you can derive the URL of the encrypted atKeys file and put it in the `install.sh` file headers

```
export ATKEYS_URL="http://192.168.1.61:8080/@ssh_1_key.atKeys.aes"
# This is the AES password you used to encrypt the above file
export ATKEY_PASSWORD="helloworld"
```

The other variables should be straight forward enough.

```
export USERNAME=ubuntu
export PASSWORD="changeme"
export CONFIG_URL="https://raw.githubusercontent.com/cconstab/sshnpd_config/main/config/sshnpd.sh"
```
USERNAME is the username of the Linux account that runs sshnpd
PASSWORD is the password of the username allowing sudo powers
CONFIG_URL is the default config file used to run sshnpd

The other variables set up the atSigns for the manager and device and the device name itself. The devaice name by default uses the `hostname`

# Running the install.sh (Note has to be run as root)
This is a simple matter now of getting the install.sh to the target device and running it. The needed files will be installed, the username name created, cronjobs put in place and the 'sshnpd' will be started.

How you get the `install.sh` file to the target machine is going to vary depending on your enviroment. Using scp is a good option or using ssh or curl and pulling the file (using the same encryption method perhaps).

# Scale test rig for sshnpd/atServer

## Set up environment
The aim of this code is to scale up N number of docker containers and be able to login to them with sshnp. The answer is 50 but with a realistic limit of 25 per atSign.

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