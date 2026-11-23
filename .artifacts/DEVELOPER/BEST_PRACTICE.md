


- godot Resource instances are shared in memory, NEVER include a Resource instance in an instantiable base .tscn


Two ways of scene instantiation:
- Instantiate .tscn > Make Local (Make Unique) > Completely Separate
- Instantiate .tscn > Editable Children > Shared Base, Completely Separate Inspector Diffs


Resource v.s. Node:
- Resource CAN be instanced INSIDE the Inspector 
- Resource CAN see runtime Nodes and Scene Trees via functions that take in one runtime node
- Node CANNOT be instanced INSIDE Inspector
- https://www.youtube.com/watch?v=knjtHyDnmgo
