# Schmove

A very slightly opinionated stab at cross-scene management in Godot4

# Overview

As direct children in each of your scenes add `SchmovementImporter2D`, configure as needed.

In anything that needs to be cross-scene, add an `SchmovementExporter2D`, configure as needed.

Now whenever you `Schmove.BeginTransition, .FinishTransition` it will carry over all Exported nodes
that got explicitly launched (or were implicitly launched by being marked Important)

## Features

- Wipe transitions via simple shaders
- Automatic free cross-scene entities including prevention of respawning unique nodes
- In depth control with a Jail system

## Guides

Coming soon, but for now the scripts are very well documented.