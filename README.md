# ssh-agent-buildkite-plugin
> Per-step ssh-agent that can be fed with files or environment variables

## Basic Usage

```yaml
- label: "Clone repo"
    plugins:
      - staticfloat/ssh-agent:
          keyvars:
            - "SSH_DEPLOY_KEY"
    commands: |
      WORKDIR="/tmp/${BUILDKITE_PIPELINE_ID}"
      mkdir -p "${WORKDIR}"
      git -C "${WORKDIR}" clone git@github.com:username/repo.git
    env:
      # base64-encoded deploy key
      SSH_DEPLOY_KEY: ...
```

Users can either provide `keyfiles` with a list of on-disk keyfiles to load, or `keyvars`, a list of environment variables that will contain a base64-encoded representation of the keyfile.
We strongly suggest using the `keyvars` form along with encrypted environment variables embedded within your `pipeline.yml`, in a manner documented at [the JuliaGPU buildkite](https://github.com/JuliaGPU/buildkite/) repository.
