# docker-freezer
Use CRIU (Checkpoint/Restore in User space) to store the state of a process in S3 and restart it

### What is it 
It's very much of an experiment using [criu](https://criu.org/), to build a base docker image (this is based on debian/jessie) 
that has a built in support to freeze a generic process, dump it to a volume and optionally to S3, and resume its execution 
when restarted.
Docker is also working on a live migration [feature based on CRIU](https://github.com/docker/docker/blob/master/experimental/checkpoint-restore.md) so chances 
are that this project will become obsolete soon. But as I said it's an experiment, and it seems to work at this stage

### Run it using a local volume

To test, you can run this image with `sleep` as the process to hibernate, and your `/tmp` directory mounted as the `/dump` volume:

```bash
$ docker run --privileged -v /tmp:/dump --name sleep alessandrob/freezer start sleep 100
```
You can capture the state of the process by sending an interrupt (for instance, press ctrl+c on the console) or by executing
```bash
$ docker exec --privileged sleep freezer freeze
```
Note that in both cases, after the process state is dumped, the container will exit.
Restart it again, with 
```bash
docker run --privileged -v /tmp:/dump --name sleep alessandrob/freezer start
``` 
and it will automatically load the state from your /tmp directory and resume where it left off (sleeping in this case...)

### Run it using S3

```bash
docker run --privileged -e S3=s3://your.bucket/ --name sleep freezer start sleep 100
```
Note that, unless you are using IAM instance roles on AWS, you will also need to provide `-e AWS_ACCESS_KEY_ID=<yourkey> -e AWS_SECRET_ACCESS_KEY=<yoursecret>`
Again, the process can be interrupted or frozen with `docker exec` as above, and the next time it start will use it's frozen state.

 