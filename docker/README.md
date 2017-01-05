# Diggit docker image

Diggit's docker image enables you to use diggit without having the burden of installing it. This image is not meant to be used directly, but rather to be extended.

To work, it needs several files:
* A `sources` file that contains the list of the URLs of the repositories
* A `plugins` folder that may contains analyses, joins or addons

To use it, create a new `Dockerfile` based on the one furnished in this repository, and add the analysis sequence as a sequence of `RUN` commands, such as:

```
FROM jrfaller/diggit

RUN dgit analyses add test_analysis
RUN dgit clones perform
RUN dgit analyses perform
```
