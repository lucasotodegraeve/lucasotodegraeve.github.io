---
title: "Project showcase: simulating logic gates"
date: 2024-03-23
---



Here's a little project I put together. It's a small logic gate simulator built with [Go](https://go.dev/) and [Raylib](https://www.raylib.com/).

## Logic Simulation

If you want to see a more flushed-out version of this idea, I highly recommend [Sebastian League's video series](https://youtube.com/playlist?list=PLFt_AvWsXl0dPhqVsKt1Ni_46ARyiCGSq&si=xtOuDfWtn7T6USgG). In my version, you start by building a small logic network using the provided gates. 

<video autoplay muted loop>
  <source src="builder.mp4" type="video/mp4">
</video>

You can move the gates around and create links between them by click-and-dragging from a gate's output socket. Gates can be removed by right-clicking on them. Switches are the inputs of the network and can be toggled later on.

Pressing enter brings you from the building screen to the simulation screen.

<video autoplay muted loop>
  <source src="runner.mp4" type="video/mp4">
</video>

Here you see the input and output values of every gate. By pressing the step button, you can advance the simulation by 1 tick. Every tick the outputs of the gates are evaluated before being propagated to other gates.  

The code is available on [Github](https://github.com/lucasotodegraeve/go-logic-gates).

## Raylib with Nix
I'm still a bit of a [Nix](https://nixos.org/) noobie so I struggled quite a bit to get Raylib working. I eventually got [these Raylib bindings](https://github.com/gen2brain/raylib-go) to work by putting the following `buildInputs` in a `mkShell`.
```nix
buildInputs = with pkgs; [
  libGL
  xorg.libXi
  wayland
  libxkbcommon
  xorg.libX11
  xorg.libXcursor
  xorg.libXrandr
  xorg.libXinerama
];
```
I wasn't brave enough to try and build the Go module the Nix way (mainly because `go mod vendor` doesn't pull all the required files from github). Calling `go build` did the job just fine.

The following was also needed once I moved the main package into a subdirectory:
```
hardeningDisable = [ "all" ];
```



