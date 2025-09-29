Dirty hack:

```
nix build github:pablito2020/testing-flakes-template --override-input mysrc path:/home/pablo/projects/test-uv --no-link --print-out-paths
```

```
nix develop github:pablito2020/testing-flakes-template --override-input mysrc path:/home/pablo/projects/test-uv --command X
```
