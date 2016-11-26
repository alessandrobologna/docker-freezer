### docker-freezer
Use CRIU (Checkpoint/Restore in User space) to store the state of a process in S3 and restart it

### What is it 

It's very much of an experiment using [criu](https://criu.org/), to build a base docker image (this is based on debian/jessie) 
that has a built in support to freeze a generic process, dump it to a volume and optionally to S3, and resume its execution 
when restarted.
Docker is also working on a live migration [feature based on CRIU](https://github.com/docker/docker/blob/master/experimental/checkpoint-restore.md) so chances 
are that this project will become obsolete soon. But as I said it's an experiment, and it seems to work at this stage.
There are still some issues, for instance I had to use a workaround to allow the resumed process to not die as soon as it start writing to the console, and create
two links for /dev/{stdout,stderr} in /var/log/freezer{stdout,stderr}, which means that the assumption is that each process will log to those two files.

### Run it using a local volume

To test, you can run this image with `sample` as the process to hibernate, and your `/tmp/dump` directory mounted as the `/dump` volume:

```bash

$ mkdir /tmp/dump
$ docker run --privileged -v /tmp/dump:/dump  alessandrob/docker-freezer start sample
Starting 'sample'
'sample' was started
Sat Nov 26 21:02:08 UTC 2016	0
Sat Nov 26 21:02:10 UTC 2016	1
Sat Nov 26 21:02:12 UTC 2016	2
Sat Nov 26 21:02:14 UTC 2016	3
Sat Nov 26 21:02:16 UTC 2016	4
```
You can capture the state of the process by sending an interrupt (for instance, press ctrl+c on the console):
```bash

Sat Nov 26 21:02:48 UTC 2016	20
Sat Nov 26 21:02:50 UTC 2016	21
Sat Nov 26 21:02:52 UTC 2016	22
^CFreezing 9
Warn  (criu/arch/x86/crtools.c:133): Will restore 55 with interrupted system call
/usr/local/bin/freezer: line 10:     9 Killed                  "$@"
Checkpoint completed
Process 9 terminated
Created valid dump
```
 or by executing
```bash

$ docker ps
CONTAINER ID        IMAGE                        COMMAND                  CREATED             STATUS              PORTS               NAMES
2285e4adcea4        alessandrob/docker-freezer   "/usr/local/bin/freez"   6 seconds ago       Up 5 seconds                            small_mahavira
dhcpb242:aws-cumulus-builder alessandro$ docker exec --privileged 2285e4adcea4 freezer freeze
Freezing 9
Warn  (criu/arch/x86/crtools.c:133): Will restore 47 with interrupted system call
Checkpoint completed
```
Note that in both cases, after the process state is dumped, the container will exit.
Restart it again, with 
```bash

$ docker run --privileged -v /tmp/dump:/dump  alessandrob/docker-freezer start sample
Found frozen process, starting it instead of sample
Sat Nov 26 21:05:14 UTC 2016	19
Sat Nov 26 21:05:16 UTC 2016	20
Sat Nov 26 21:05:18 UTC 2016	21
``` 
and it will automatically load the state from your `/tmp/dump` directory and resume where it left off

### Run it using S3

Note: in the examples below, please replace the AWS secrets and bucket with your own.
```bash

$ docker run --privileged  -e AWS_ACCESS_KEY_ID=<yourkey> -e AWS_SECRET_ACCESS_KEY=<yoursecret> -e S3=s3://<yourbucket>/ alessandrob/docker-freezer start sample
Trying to load dump from s3://<yourbucket>/
No valid S3 snapshot found
Starting 'sample'
'sample' was started
Sat Nov 26 21:10:19 UTC 2016	0
Sat Nov 26 21:10:21 UTC 2016	1
Sat Nov 26 21:10:23 UTC 2016	2
Sat Nov 26 21:10:25 UTC 2016	3
Sat Nov 26 21:10:27 UTC 2016	4
Sat Nov 26 21:10:29 UTC 2016	5
```

Note that if you are using IAM instance roles on AWS and running this there, you will not need to provide secrets.
Press ctrl-c, or use `docker exec` as above, and then test resuming:
```bash

$ docker run --privileged  -e AWS_ACCESS_KEY_ID=<yourkey> -e AWS_SECRET_ACCESS_KEY=<yoursecret> -e S3=s3://<yourbucket>/ alessandrob/docker-freezer start sample
Trying to load dump from s3://<yourbucket>/
Found valid S3 snapshot
Found frozen process, starting it instead of sample
Sat Nov 26 21:10:45 UTC 2016	6
Sat Nov 26 21:10:47 UTC 2016	7
Sat Nov 26 21:10:49 UTC 2016	8
Sat Nov 26 21:10:51 UTC 2016	9
Sat Nov 26 21:10:53 UTC 2016	10
Sat Nov 26 21:10:55 UTC 2016	11
Sat Nov 26 21:10:57 UTC 2016	12
Sat Nov 26 21:10:59 UTC 2016	13
Sat Nov 26 21:11:01 UTC 2016	14
Sat Nov 26 21:11:03 UTC 2016	15
Sat Nov 26 21:11:05 UTC 2016	16
```
 