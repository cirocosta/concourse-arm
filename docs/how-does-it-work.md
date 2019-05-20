# how does it work?

Getting Concourse workers to run on ARM-based devices doesn't take much more than making sure that the dependencies that Concourse depends on run properly there - once the dependencies have been properly figured out, building and running Concourse itself is fairly easy.

Here's a "not-too-deep" dive into that.


## the worker

To run any types of steps, a `web` node interacts with a worker that at some point registered with the cluster and offered at least two specific services:

1. creation & deletion of volumes, and
2. creation & deletion of containers.

The interfaces that allows that to happen in a fairly decoupled way are (respectively):

1. [garden](https://github.com/cloudfoundry/garden), and
2. [baggageclaim](https://github.com/concourse/baggageclaim).

Once those two components are in place, the rest of the `worker` code can be thought of as the thing that ensure that the "worker entity" is alive and that it's connected to a `web` node - this is the job of what we call "the beacon".


## the implementations

While the "beacon" is just plain platform-agnostic Go code, `baggageclaim` and `garden` implementations are more specialized.


