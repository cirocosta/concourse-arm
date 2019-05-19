# concourse-arm

## building from source

1. clone this repo with all submodules

```
git clone https://github.com/cirocosta/concourse-arm --recurse-submodules -j2
```

2. the `cirocosta/concourse-arm:(arm64|armhf)` images

```
make images -j4
```

