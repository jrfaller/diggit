# Diggit docker image

Diggit's docker image enables you to use diggit without having the burden of installing it.

First you have to hack the `run.sh` script of the `docker` folder to furnish the list of diggit commands you want to perform.

Then you can compile the docker image inside the `docker` folder `docker build . -t diggit`.

Finally you can launch your diggit analyses: `docker run -v my_folder:/diggit diggit`.
