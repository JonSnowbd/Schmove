# Schmove

A very slightly opinionated stab at cross-scene management in Godot4

# Overview

As direct children in each of your scenes add `SchmovementImporter2D`, configure as needed.

In anything that needs to be cross-scene, add an `SchmovementExporter2D`, configure as needed.

Now whenever you `Schmove.BeginTransition, .FinishTransition` it will carry over all Exported nodes
that got explicitly launched (or were implicitly launched by being marked Important)

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

This is exclusively a 2d aimed plugin, it will override 3d_navigation_layer settings
in your project settings Layer Names to implement the custom named bitset flags.

If things arent working, triple check that entities are near the top level,
or configure deep_search_depth in project settings to determine how deep
into a node nest Schmove will look for exporters