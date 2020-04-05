# Diggit's docker image

Diggit's docker image enables you to use diggit without having the burden of installing it.

## Installation

You can just pull the image by running `docker pull jrfaller/diggit`.

You can also compile it your self, from the root of the diggit repository clone. Just run `docker build . -f docker/Dockerfile -t jrfaller/diggit` and you're done.

## Usage

To run a diggit container you have to bind the `data` folder to a folder from the host. I recommend create an empty folder and run docker directly from inside it such as: `docker run -v $PWD:/data jrfaller/diggit init`.

Of course you can run any diggit command after that, such as `docker run -v $PWD:/data jrfaller/diggit status`.
