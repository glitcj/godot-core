"""Generator for ../editor-plugin-classes.ipynb (run with python3)."""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(os.path.dirname(HERE), "editor-plugin-classes.ipynb")

CELL = """# Godot editor plugin classes: who is who

Three kinds of class, and the kind tells you how to use it:

- **You extend it**: Godot calls your `_underscore` functions at the right moment.
- **You ask for it**: one already exists; you fetch it and call its functions.
- **You connect to it**: it tells you when something changed.

| Class | Kind | What it is | How you get it | Functions you use most | In the RPGM plugin |
|---|---|---|---|---|---|
| `EditorPlugin` | extend | The entry point. Registers everything your plugin adds | `plugin.cfg` points at your script | `_enter_tree`, `_exit_tree`, `add_control_to_bottom_panel`, `add_control_to_dock`, `add_inspector_plugin`, `add_tool_menu_item`, `_has_main_screen`, `_make_visible` | `plugin.gd` |
| `EditorInterface` | ask | The front desk. Hands you every other editor service | Use the name directly: `EditorInterface.` | `get_selection`, `get_editor_undo_redo`, `get_editor_theme`, `get_editor_scale`, `get_inspector`, `get_editor_main_screen`, `edit_node` | Used in every file |
| `EditorSelection` | ask + connect | What is selected in the Scene tree | `EditorInterface.get_selection()` | `get_selected_nodes`, signal `selection_changed` | The dock follows it |
| `EditorUndoRedoManager` | ask + connect | The editor's undo history. The right way to change scene data | `EditorInterface.get_editor_undo_redo()` | `create_action`, `add_do_property`, `add_undo_property`, `add_do_method`, `commit_action`, signal `history_changed` | `_commit_queue`, `_commit_value`, and every redraw |
| `EditorInspectorPlugin` | extend | A hook into how the Inspector is built for one kind of object. Draws nothing itself | `add_inspector_plugin(MyPlugin.new())` in the `EditorPlugin` | `_can_handle`, `_parse_begin`, `_parse_property`, `_parse_end`, `add_custom_control`, `add_property_editor` | `_rpgm_plugin_inspector.gd`, `_rpgm_plugin_script_inspector.gd` |
| `EditorProperty` | extend | One Inspector row for one property | Created in `_parse_property`, passed to `add_property_editor` | `_update_property` (read), `emit_changed` (write), `get_edited_object`, `get_edited_property`, `set_bottom_editor` | `_rpgm_plugin_lambda_queue_property.gd` |
| `EditorInspector` | ask | The Inspector panel itself, and a factory for the stock row of any type | `EditorInterface.get_inspector()` | `instantiate_property_editor` (static), `get_edited_object`, signal `property_edited` | Value editors in the dock's right pane |
| `EditorFileSystem` | ask + connect | The editor's view of `res://` | `EditorInterface.get_resource_filesystem()` | `scan`, signal `filesystem_changed` | Not used yet |
| `EditorSettings` | ask | The user's editor preferences | `EditorInterface.get_editor_settings()` | `get_setting`, `set_setting` | Not used yet |
| `EditorScript` | extend | A one-off script run from the script editor (File > Run). Not part of a plugin | Write a `@tool` script that extends it | `_run`, `get_scene` | Not used |

**Easy to mix up**

- `EditorInspectorPlugin` decides *which* rows appear; `EditorProperty` *is* a row; `EditorInspector` is the panel that holds them.
- `EditorPlugin` adds things to the editor; `EditorInterface` is how you read the editor's current state.
- A dock or bottom panel has no special class. It is any `Control` you hand to `EditorPlugin`.
"""

nb = {"cells": [{"cell_type": "markdown", "metadata": {}, "source": CELL.splitlines(keepends=True)}],
      "metadata": {"kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
                   "language_info": {"name": "python"}},
      "nbformat": 4, "nbformat_minor": 5}
json.dump(nb, open(OUT, "w"), indent=1)
print("wrote", OUT)
