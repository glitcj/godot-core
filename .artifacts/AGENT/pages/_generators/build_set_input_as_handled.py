"""Generator for ../set-input-as-handled.ipynb (run with python3)."""
import sys, json, os

sys.path.insert(0, os.path.expanduser("~/.claude-glitcj/skills/page"))
from render_dot import dot_md, dot_png

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), "set-input-as-handled.ipynb")

D = '''
digraph {
  press  [label="key press"];
  plugin [label="1. _input\\nthe _core_shortcuts plugin"];
  match  [label="is it one of\\nthe plugin's keys ?", fillcolor="#fff3b0", color="#c9a400"];
  mine   [label="plugin acts, then\\nset_input_as_handled()\\nthe event stops here", fillcolor="#d4f4dd", color="#3c9a5f"];
  later  [label="2. _gui_input\\n3. _shortcut_input\\n4. _unhandled_input\\neditor behaves as normal"];
  press -> plugin -> match;
  match -> mine  [label="yes"];
  match -> later [label="no, early return"];
}
'''

CELL = """# Page: `set_input_as_handled()` in the shortcuts plugin

```gdscript
if key.physical_keycode == KEY_RIGHT: bottom_dock.select_next_available()
else: bottom_dock.select_previous_available()
get_viewport().set_input_as_handled()
```

That last line marks the key event as **consumed**. The plugin sees every key first, in `_input`; a consumed event is not passed on, so the editor's own shortcut for the same keys never runs.

""" + dot_md(D, alt="A key press reaches the plugin first; its own keys are handled and stopped, all other keys continue to the editor") + """

| Order | Stage | Who uses it | Sees a handled event ? |
|---|---|---|---|
| 1 | `_input` | this plugin | yes, it is the one handling it |
| 2 | `_gui_input` | the focused control, e.g. the code editor | no |
| 3 | `_shortcut_input` | editor shortcuts, e.g. script history back / forward | no |
| 4 | `_unhandled_key_input`, `_unhandled_input` | whatever is left | no |
| every frame | `_process` | per-frame logic, e.g. animation | never receives events at all |
| every physics tick | `_physics_process` | movement and collisions | never receives events at all |

- **Plugin key, line present:** only the plugin's action happens.
- **Plugin key, line removed:** the plugin's action **and** the editor's default action both happen.
- **Any other key:** early `return` before the line, so the editor behaves as normal.

**`_process` and `_physics_process` are not input stages.** Godot has no `_input_process` or `_input_physics`. These two run on a timer (every frame, every physics tick) whether or not a key was pressed, and are handed only `delta`, never the event.

Code in them can still *ask* about keys, e.g. `Input.is_key_pressed(KEY_F11)`. That reads the keyboard's current state, which `set_input_as_handled()` does not change: a handled key still reads as pressed there.
"""

nb = {"cells": [{"cell_type": "markdown", "metadata": {}, "source": CELL.splitlines(keepends=True)}],
      "metadata": {"kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
                   "language_info": {"name": "python"}},
      "nbformat": 4, "nbformat_minor": 5}
json.dump(nb, open(OUT, "w"), indent=1)
print("wrote", OUT, os.path.getsize(OUT) // 1024, "KB")

if "--preview" in sys.argv:
	open(sys.argv[sys.argv.index("--preview") + 1], "wb").write(dot_png(D))
