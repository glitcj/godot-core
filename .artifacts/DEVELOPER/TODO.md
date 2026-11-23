
Claude ignores this files, this file is only for the human developer to see, use, and maintain.

- Add RPGM UnitEditor:
https://www.youtube.com/watch?v=knjtHyDnmgo


- Refactor _RPGM to _RPGM everywhere

- /Users/alhabib/Desktop/glitcj-repos/godot-core/viewports/rpgm/_rpgm.gd:48
48: # TODO: FIX collect AND apply_state, they should load the correct _RPGM_Data

- _Core_Data and _RPGM_Data _RPGM_Variable _Core_Variable

- Add a "Add Event" that generates an event on the go ? use godot native ?

- Code Dev v.s. Data Dev Finish COMPLETE EDITOR that does not need scipts at all

- Run the Event Creating via lambda queues flow several times until comfortable

- Replace all existing events with Lambda Queued events

- Replace _RPGM with _RPGM_Viewport and _RPGM with _RPGM ? Same for _DGM

- Refactor Viewport to be super clean and clear

- Make RPGM Editor SUPER TIGHT, Super Tight means: The user does NOT TOUCH ANY CODE, only plays with the editor. E.g., Running lambdas is MUST NOT BE CODE. i.e., Add _Core_Lambda and _Core_Lambda_Queue

- Add _Core_Lambda and _Core_Lambda_Queue

- Refactor and finish _RPGM_Script

- Remove Disctinction between RPGM and DGM, both share same lambdas and system

- Fader with shader to hide shadered sprites and have cool digimon 3 style fade out shaders

- add teleporters to DGM rooms in RPGM

- finish viewport fader in out, parameter slider and tweener

- finish persona puzzle story

- refactor engine, make sure engine is sturdy before seriously adding scenes

- fix horrible _is_active _rpgm_script pattern, replace with dirty-clean pattern
