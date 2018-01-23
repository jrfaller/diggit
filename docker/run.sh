#!/bin/sh
dgit init
# configure your sources here
dgit sources add https://github.com/jrfaller/diggit.git
# configure your analyses here
dgit analyses add conflict_merge
# launch dgit
dgit clones perform
dgit analyses perform
