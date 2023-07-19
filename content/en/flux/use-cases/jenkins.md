---
title: Jenkins + Flux
linkTitle: Jenkins + Flux
description: "How to use Jenkins CI for building images together with Flux's image update automation."
weight: 50
---

{{% alert color="warning" title="Disclaimer" %}}
Note that this guide has not been updated since more than a year ago, it does not address Kubernetes 1.24 or above, and needs to be refreshed.

Expect this doc to either be archived soon, or to receive an overhaul.
{{% /alert %}}

This guide explains how to configure Flux with Jenkins, with the core ideas of [GitOps Principles] in mind. Let Jenkins handle CI (or Continuous Integration: image build and test, tagging and pushing), and let Flux handle CD (or Continuous Deployment) by making use of the Image Update Automation feature.

## Declarative Artifacts

In traditional CI/CD systems like Jenkins, the CI infra is often made directly responsible for continuous delivery. Flux treats this arrangement as dangerous, and mitigates this risk by prescribing encapsulation of resources into declarative artifacts, and a strict boundary separating CI from CD.

Jenkins (or any CI system generally speaking) can be cumbersome, and CI builds are an imperative operation that can succeed or fail including sometimes for surprising reasons. Flux obviates any deploy-time link between Jenkins and production deployments, to fulfill the promises of increased reliability and repeatability with GitOps.

### Git Manifests

Flux requires YAML manifests to be kept in a git repository or similar artifact hosting, (such as bucket storage which can also be configured to maintain a revision history.) Each revision represents a new "desired state" for the cluster workloads.

Flux represents this as a [`GitRepository` custom resource](/flux/components/source/gitrepositories/).

Flux's Source Controller periodically reconciles the config repository where the cluster's YAML manifests are maintained, pulling the latest version of the named ref. To invoke the continuous deployment functionality we use a `ref` which may be updated, such as a branch or tag. Flux deploys updates from whatever commit is at the ref, every `spec.interval`.

A revision can be any commit at the head of the branch or tag, or a specific commit hash described in the field `spec.ref` in the `GitRepository`. We could also specify a semver expression here, so that Flux infers the latest tag within a range specified. There are many possible configurations.

A specific commit hash can also be listed in the `GitRepositoryRef`, though this is less common than pointing to a branch, as in this case Flux is no longer performing continuous delivery of changes, but instead reconciles with some specific fixed revision as listed and curated by hand. This behavior, though not particularly ergonomic, could be useful during an [incident response](/flux/guides/image-update/#incident-management).

Pinning to a particular revision allows an operator to handle updates explicitly and manually but still via GitOps. While this effectively disables some automated features of Flux, it is also a capable way to operate. Jenkins jobs could also write commit hashes into manifests, and while cats can live with dogs, this is not important for this example.

When adopting Flux's approach to GitOps, Jenkins should not `kubectl apply` your manifests anymore. Jenkins does not need direct access to any production clusters. The responsibilities of Jenkins are reduced from a traditional CI/CD system which does both, to only CI. The CD job is delegated entirely to Flux. From the perspective of a production cluster, Jenkins' responsibility has ended once an image artifact is built and tested, after it has been tagged for deployment and pushed to the Image Repository.

### Image Repository

Jenkins is responsible for building and testing OCI images. Those images can be tested internally on Jenkins as part of the build, before pushing, or once deployed in a non-production cluster or other staging context.

Jenkins workflows are often as varied and complex as a snowflake. Finer points of Jenkins image building are not in scope for this guide, but links and some examples are provided to show a strategy that can be used on Jenkins with Flux.

If you're getting started and maybe have not much experience with Jenkins, (or if perhaps it was the boss who said to use Jenkins,) we hope this information comes in handy.

#### Jenkins Builds OCI Images

While many companies and people may use Jenkins for building Docker images, it isn't actually true that Jenkins builds Docker images.

Docker builds OCI images, and Jenkins can shell out to Docker to build images.

Jenkins always uses some other tool to build OCI images. Docker may still be the most commonly reported such tool in use as of this writing, but other tools are growing in popularity like [Porter], [Buildpacks.io], [Earthfile], and many others we have not seen, many which could be used with Jenkins.

One might use [declarative pipelines] to include the CI configuration in application repos by writing a Jenkinsfile to suit your own needs. We might use the [docker plugin], or a privileged pod with HostPath volume to mount `/var/run/docker.sock`. There are many strategies; this example only shows one way.

#### Security Concerns

This should attract the attention of InfoSec advocates, as privileged pods and HostPath volumes are generally acknowledged as **extremely dangerous**.

You should not ever do these things without understanding the risks. Don't run untrusted code from an unverified source, anywhere near a production cluster. (OK, that's fine, and we already acknowledged that Jenkins-CI is to be completely separated from production, according to Flux...)

#### Dockershim was formally deprecated

We might also be running Jenkins on a Kubernetes cluster that [doesn't even have Docker underneath]. In this case you may want to use another tool to produce OCI images with Jenkins.

Here, we will use a privileged pod with access to Docker on the host to its most positive effect, by building the image on a single node cluster which is specially earmarked and set aside for Jenkins builds.

This is so that we can leverage Docker's node-local image storage while building and testing images. When the next stage of the pipeline is executed after an image is built, there is no need to push or pull from a remote image registry as we are on the same machine where the image was built.

Now while this strategy is efficient, it will only work if Kubernetes is running Docker underneath (and that is certainly getting less common now, though it should fortunately remain possible into the future now that [Mirantis has taken over support of dockershim].)

##### CI is out of scope for Flux

Jenkins users will have to find a way of making sense of all this, depending on the details of your situation. None of this is reasonably in scope for Flux to solve, as Flux separates the responsibilities of CI and CD across these well-defined boundaries.

Whatever tool you use for building images, this document aims to explain and show compatible choices that work well with Flux.

It should be clear that if we use Jenkins or Docker, or any other competing tool for building images, much of the same advice for working with Flux will still apply.

#### What Should We Do?

We recommend users implement SemVer and/or [Sortable image tags][Sortable image tags], to enable the use of [Image Update Policies][image update guide]. It is possible for Jenkins to drive deployments with Flux in this way securely through tags, without direct access or explicit coordination with production environment or staging clusters.

GitOps principles suggest that we should manage production workloads as purely declarative artifacts that accurately describe the cluster state in enough detail to reproduce, including version information. Extrapolating the principles, we can also prescribe updates to container images with an automated process, and appropriately constrain this process to only new SemVer releases within a specified range.

#### Documentation References

Many parts are needed for a complete continuous delivery pipeline with Jenkins and Flux.

The reference below shows how to build and tag Docker images with Jenkins for development environments, for executing tests in a pipeline stage, and lastly tagging a release version for deployment in a production setting.

##### Testing Infrastructure

We can do testing without an image registry or pushing or pulling any image, because Jenkins builds the image locally on the build node, with a privileged pod that has direct access to Docker on the host. This is significantly faster than pushing before testing.

So (if we're using a single-node cluster for Jenkins, or by some other tricks perhaps ...) the image is created and used with the single node's Docker daemon.

Those are some assumptions that you may need to check on... anyway, then we tag and push an image any time a new release version was tagged in Git, only after seeing the tests pass.

##### `jenkinsci/pipeline-examples` repo

Jenkins provides examples of declarative pipelines that use [credentials] and show how you can use string data elements collected or composed in earlier stages, to drive downstream stages or scripts in different ways, or simply [populating environment variables].

Another example executes certain workflow scripts [only against a particular branch]. We may need to do all of these things, or similar ideas, in order to test and release new versions of our app in production.

For more information on Jenkins pipelines, visit the [jenkinsci/pipeline-examples] declarative examples.

## Example Jenkinsfile

Adapt this if needed, or add this to a project repository with a `Dockerfile` in its root, as a file `Jenkinsfile`, and configure a [Multibranch Pipeline][Creating a Multibranch Pipeline] to trigger when new commits are pushed to any branch or tag.

Find this example in context at [kingdonb/jenkins-example-workflow] where it is connected with a Jenkins server, and configured to build and push images to [docker.io/kingdonb/jenkins-example-workflow].

```groovy
dockerRepoHost = 'docker.io'
dockerRepoUser = 'kingdonb' // (Username must match the value in jenkinsDockerSecret)
dockerRepoProj = 'jenkins-example-workflow'

// these refer to a Jenkins secret "id", which can be in Jenkins global scope:
jenkinsDockerSecret = 'docker-registry-account'

// blank values that are filled in by pipeline steps below:
gitCommit = ''
branchName = ''
unixTime = ''
developmentTag = ''
releaseTag = ''

pipeline {
  agent {
    kubernetes { yamlFile "jenkins/docker-pod.yaml" }
  }
  stages {
    // Build a Docker image and keep it locally for now
    stage('Build') {
      steps {
        container('docker') {
          script {
            gitCommit = env.GIT_COMMIT.substring(0,8)
            branchName = env.BRANCH_NAME
            unixTime = (new Date().time.intdiv(1000))
            developmentTag = "${branchName}-${gitCommit}-${unixTime}"
            developmentImage = "${dockerRepoUser}/${dockerRepoProj}:${developmentTag}"
          }
          sh "docker build -t ${developmentImage} ./"
        }
      }
    }
    // Push the image to development environment, and run tests in parallel
    stage('Dev') {
      parallel {
        stage('Push Development Tag') {
          when {
            not {
              buildingTag()
            }
          }
          steps {
            withCredentials([[$class: 'UsernamePasswordMultiBinding',
              credentialsId: jenkinsDockerSecret,
              usernameVariable: 'DOCKER_REPO_USER',
              passwordVariable: 'DOCKER_REPO_PASSWORD']]) {
              container('docker') {
                sh """\
                  docker login -u \$DOCKER_REPO_USER -p \$DOCKER_REPO_PASSWORD
                  docker push ${developmentImage}
                """.stripIndent()
              }
            }
          }
        }
        // Start a second agent to create a pod with the newly built image
        stage('Test') {
          agent {
            kubernetes {
              yaml """\
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: test
                    image: ${developmentImage}
                    imagePullPolicy: Never
                    securityContext:
                      runAsUser: 1000
                    command:
                    - cat
                    resources:
                      requests:
                        memory: 256Mi
                        cpu: 50m
                      limits:
                        memory: 1Gi
                        cpu: 1200m
                    tty: true
                """.stripIndent()
            }
          }
          options { skipDefaultCheckout(true) }
          steps {
            // Run the tests in the new test container
            container('test') {
              sh (script: "/app/jenkins/run-tests.sh")
            }
          }
        }
      }
    }
    stage('Push Release Tag') {
      when {
        buildingTag()
      }
      steps {
        script {
          releaseTag = env.TAG_NAME
          releaseImage = "${dockerRepoUser}/${dockerRepoProj}:${releaseTag}"
        }
        container('docker') {
          withCredentials([[$class: 'UsernamePasswordMultiBinding',
            credentialsId: jenkinsDockerSecret,
            usernameVariable: 'DOCKER_REPO_USER',
            passwordVariable: 'DOCKER_REPO_PASSWORD']]) {
            sh """\
              docker login -u \$DOCKER_REPO_USER -p \$DOCKER_REPO_PASSWORD
              docker tag ${developmentImage} ${releaseImage}
              docker push ${releaseImage}
            """.stripIndent()
          }
        }
      }
    }
  }
}
```

The example above should do the necessary work for building, tagging, and pushing images for development and production.

### Instructions for Use

Fork the repo from [kingdonb/jenkins-example-workflow], to see the other details like a basic suitable example [Dockerfile], the [jenkins/docker-pod.yaml], and the [jenkins/run-tests.sh] script.

Create a Multibranch Pipeline and associate it with your repository. Configure it to build commits from at least one branch (or all branches) and any tags.

#### Development Image

When you push a commit to a branch, it will be built and tested locally on the Jenkins node, and also a dev image is pushed in parallel to the image repository.

This image is tagged with a [Sortable image tag][Sortable image tags] of the format `{branch}-{sha}-{ts}`.

This can be deployed automatically by Flux, with a more relaxed policy for development environments. There is no requirement that tests must pass in order to deploy the latest image in development. You can add such a requirement later, or change this in any way that makes sense for your use case.

#### Release `SemVer` Image

We will confirm the tests are passing before pushing any production tag, in the `Push Release Tag` stage, which only runs after our `Test` stage has succeeded.

The corresponding Flux resource is covered in the [using an ImagePolicy object] section of the aforementioned guide.

When you push a git tag, different workflow is used because of:

```
when {
  buildingTag()
}
```

and

```
when {
  not {
    buildingTag()
  }
}
```

This is important since git tags can be used for [Automating image updates to Git](/flux/guides/image-update/) in production.

Using SemVer tags, you can automatically promote new tags to production via policy.

In this guide we assume you will manually create and push Git tags whenever needed, then promote them through the pipeline. These builds will run `docker build` again for the tag, which should hit the cache and complete quickly, then run tests again, and finally on success push a SemVer image tag.

#### Example Resources

You can find this example tested with a Jenkins instance at [kingdonb/jenkins-example-workflow]; it has been configured to run as you can see from the commit status checks found on all commits, tags, and pull requests. The images are pushed to [docker.io/kingdonb/jenkins-example-workflow].

Configuration of webhooks would be a logical next step if not already configured and working, so that Jenkins can trigger builds without polling or manual intervention by an operator. Demonstrating this advanced CI feature of Jenkins is again something that is out of scope for this guide.

#### Wrap Up

By pushing image tags, Jenkins can update the cluster using Flux's pull-based model for updating. When a new image is pushed that has a newer image tag, and meets the filters of the configured policy, Flux is made aware of it by Image Reflector API, which captures the new candidate tag as an Image resource.

Your CI workflow can be based on these examples, or may turn out completely different. Jenkins has a rich ecosystem of plugins, and the Jenkinsfile is as diverse and powerful as any programming language. If you are using Jenkins already, you probably already know exactly how you want it to build images.

If you are concerned about running Docker and Kubernetes together, or if you need to use these workflows in a cluster that cannot run container images as root, or in privileged mode, for an alternative build strategy that can still work with Jenkins in rootless mode, we recommend you check out [Kubernetes examples for Buildkit] and the [Buildkit CLI for Kubectl].

These were recently presented together at [KubeCon/CloudNativeCon EU 2021].

The finer points of building OCI images in Jenkins are out of scope for this guide. These examples are meant to be kept simple, though complete, and we refrain from sharing strong opinions about how CI should work here, because it's simply out of scope for Flux to weigh in about these topics. We meant to show some ways that Jenkins CI, or any similar functioning tool, can be used with Flux.

This works without Jenkins connecting to production clusters, only building images, and Flux only receives published image tags. So there is no strong coupling or inter-dependency between CI and CD!

Update deployments via Flux's [ImagePolicy] CRD, and the Image Update Automation API.

[GitOps Principles]: https://www.gitops.tech/#how-does-gitops-work
[Porter]: https://porter.sh
[Buildpacks.io]: https://buildpacks.io
[Earthfile]: https://earthly.dev
[declarative pipelines]: https://www.jenkins.io/doc/book/pipeline/docker/
[docker plugin]: https://plugins.jenkins.io/docker-plugin/
[doesn't even have Docker underneath]: https://kubernetes.io/blog/2020/12/02/dockershim-faq/#why-is-dockershim-being-deprecated
[Mirantis has taken over support of dockershim]: https://www.mirantis.com/blog/mirantis-to-take-over-support-of-kubernetes-dockershim-2/
[Sortable image tags]: /flux/guides/sortable-image-tags/
[image update guide]: /flux/guides/image-update/
[credentials]: https://github.com/jenkinsci/pipeline-examples/blob/master/declarative-examples/simple-examples/credentialsUsernamePassword.groovy
[populating environment variables]: https://github.com/jenkinsci/pipeline-examples/blob/master/declarative-examples/simple-examples/scriptVariableAssignment.groovy
[only against a particular branch]: https://github.com/jenkinsci/pipeline-examples/blob/master/declarative-examples/simple-examples/whenBranchMaster.groovy
[jenkinsci/pipeline-examples]: https://github.com/jenkinsci/pipeline-examples/tree/master/declarative-examples
[Creating a Multibranch Pipeline]: https://www.jenkins.io/doc/book/pipeline/multibranch/#creating-a-multibranch-pipeline
[kingdonb/jenkins-example-workflow]: https://github.com/kingdonb/jenkins-example-workflow
[docker.io/kingdonb/jenkins-example-workflow]: https://hub.docker.com/r/kingdonb/jenkins-example-workflow/tags?page=1&ordering=last_updated
[Dockerfile]: https://github.com/kingdonb/jenkins-example-workflow/blob/main/Dockerfile
[jenkins/docker-pod.yaml]: https://github.com/kingdonb/jenkins-example-workflow/blob/main/jenkins/docker-pod.yaml
[jenkins/run-tests.sh]: https://github.com/kingdonb/jenkins-example-workflow/blob/main/jenkins/run-tests.sh
[using an ImagePolicy object]: /flux/guides/sortable-image-tags/#using-in-an-imagepolicy-object
[Kubernetes examples for Buildkit]: https://github.com/moby/buildkit/tree/master/examples/kubernetes
[Buildkit CLI for Kubectl]: https://github.com/vmware-tanzu/buildkit-cli-for-kubectl
[KubeCon/CloudNativeCon EU 2021]: https://www.youtube.com/watch?v=vTh6jkW_xtI
[ImagePolicy]: /flux/guides/sortable-image-tags/#using-in-an-imagepolicy-object
