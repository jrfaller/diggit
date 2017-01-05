# Diggit docker image

Diggit's docker image enables you to use diggit without having the burden of installing it.

To use it you need to mount a folder from the host to `/diggit`. Then you can use docker run to perform diggit commands.
Here is an example of usage:

```
docker run -v my_folder:/diggit jrfaller/diggit init
docker run -v my_folder:/diggit jrfaller/diggit analyses add tex
docker run -v my_folder:/diggit jrfaller/diggit sources add https://github.com/jrfaller/test-git
docker run -v my_folder:/diggit jrfaller/diggit clones perform
docker run -v my_folder:/diggit jrfaller/diggit analyses perform
```
