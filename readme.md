# Schmove

A very slightly opinionated stab at cross-scene management in Godot4

# Overview

As children in each of your scenes add `SchmoveImporter2D`, configure as needed. These will be where
your nodes will get teleported into. Make sure they have atleast one group they allow.

In anything that needs to be cross-scene, add an `SchmoveExporter2D`, configure as needed. This node will make sure
that when you `Schmove.Begin/Finish` (and its an important node) it will move along to the next scene. Having this node
in a node also enables it for being targeted by `.transition_launch, .jail` etc

In anything that needs to remember state, add a `SchmoveStatic2D`, and the encode/decode pair will automatically be called on scene
transition, and recalled state on _ready

Now whenever you `Schmove.BeginTransition, .FinishTransition` it will carry over all Exported nodes
that got explicitly launched (or were implicitly launched by being marked Important)

## Encode/Decode pairs

If any of your `Static` or `Exporter` node's parents have a `schmove_encode() -> Dictionary` and a `schmove_decode(data: Dictionary)`, they
will have their state saved in the save file, and will recall their previous states via `schmove_decode`

## Features

- Wipe transitions via simple shaders
- Automatic free cross-scene entities
- In depth control of entities with a Jail system

## Guides

Coming soon, but for now the scripts are very well documented.

## Tips

Turn on advanced settings in your project settings to see a schmove menu for
both layer names, and general settings

## Huh??

This is exclusively a 2d aimed plugin, a 3d version would not be hard to start on,
but I have no interest in starting it for now.