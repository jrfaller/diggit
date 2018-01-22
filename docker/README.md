# Diggit docker image

Diggit's docker image enables you to use diggit without having the burden of installing it.

First you have to compile the docker image using the `Dockerfile` of our `docker` folder using this command: `docker build . -t diggit`.

Then you have to hack the `run.sh` script of our `docker` folder to furnish the list of diggit commands you want to perform. Place this file in an empty folder that will be the folder where you will perform your diggit commands.

Finally you have to launch diggit: `docker run -v /my_folder:/diggit diggit`, `my_folder` being the folder where the `run.sh` file is located.
