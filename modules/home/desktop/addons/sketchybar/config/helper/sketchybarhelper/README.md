# SketchyBar Helper
This demo implementation shows how to directly communicate with
[SketchyBar](https://github.com/FelixKratz/SketchyBar) from C or C++ to create
advanced and fast helper programs.

### Sending Messages to SketchyBar
The relevant function to send messages to SketchyBar is defined in the
`sketchybar.h` header:
```c
char* sketchybar(char* message);
```
it takes a message, e.g. "--query bar", and returns the response from
sketchybar.

### Receiving Events from SketchyBar (SketchyBar >= v2.9.0)
Additionally you can run the event server, which makes the helper listen for
event calls from SketchyBar:
```c
void event_server_begin(mach_handler handler, char* mach_helper);
```
where the `handler` is a function pointer to a function where all events are
handled:
```c
void handler(env env);
```
and the `mach_helper` string is used to register the helper.

In SketchyBar (starting from v2.9.0) the helper needs to be registered for an
item, e.g 
```bash
sketchybar --set <name> mach_helper=<string>
```
where the string is the same as used to register the helper.

Note: The helper must run *before* the `mach_helper` property in SketchyBar is
set.

## Compile
To compile the example run:
```bash
clang -std=c99 helper.c -o helper
```
You could decide to copy the helpers source code to the sketchybar config and
compile and run it automatically in sketchybarrc:
```bash
HELPER=git.felix.helper
killall helper
cd $HOME/.config/sketchybar/helper && make
$HOME/.config/sketchybar/helper/helper $HELPER &
```
