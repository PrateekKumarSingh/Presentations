# Introduction

Jupyter notebooks has benefited the Python ecosystem vastly by reducing the barrier
to entry, it facilitates interactive programming for .NET environments as well.

Follow these steps

* Install Jupyter
* Install .NET Core and its SDK
* Install .NET interactive global tool

```bash
dotnet tool install -g --verbosity normal --add-source "https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet-tools/nuget/v3/index.json" Microsoft.dotnet-interactive
```

* Install the .NET Kernels

```bash
# install it
dotnet interactive jupyter install

# Verify it
jupyter kernelspec list
```

* Run the jupyter lab and start exploring notebooks

```bash
jupyter lab
```
