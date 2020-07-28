# Vim Instructions

Vim is a “modal” text editor based on the vi editor. In Vim, the mode that the editor is in determines whether the alphanumeric keys will input those characters or move the cursor through the document. Listed below are some basic commands to move, edit, search and replace, save and quit.

|Vim Command             | Description
|------------------------|--------------------------------------------------------------|
| i                      | Enter insert mode |
| Esc                    | Enter command mode |
| x or Del               | Delete a character |
| X                      | Delete character is backspace mode |
| u                      | Undo the last operation |
| Ctrl + r               | Redo the last undo |
| yy                     | Copy a line |
| d                      | Starts the delete operation |
| dw                     | Delete a word |
| d0                     | Delete to the beginning of a line |
| d$                     | Delete to the end of a line |
| dd                     | Delete a line |
| p                      | Paste the content of the buffer |
| /<search_term>         | Search for text and then cycle through matches with n and N |
| [[ or gg               | Move to the beginning of a file |
| ]] or G                | Move to the end of a file |
| :%s/foo/bar/gci        | Search and replace all occurrences with confirmation |
| Esc + :w               | Save changes |
| Esc + :wq or Esc + ZZ  | Save and quit Vim |
| Esc + :q!              | Force quit Vim discarding all changes |

If you need any further assistenace, feel free to ask your bootcamp host.

---
**Page navigation**  
[Top of Page](#top) | [Home](/README.md) | [Full Task List](/README.md#prod-k8s-cluster-tasks)
