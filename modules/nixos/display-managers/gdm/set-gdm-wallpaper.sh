#! /bin/sh
set -e
if ! hash gresource 2>/dev/null; then
    echo "gresource binary not found. "
    echo " "
    echo "Please install glib2 or glib2-devel"
    echo " "
    echo "Fedora:"
    echo "# dnf install glib2-devel"
    exit 1
fi
if [ "$#" -eq "0" ]; then
    echo 'Usage:'
    echo '  set-gdm-wallpaper [FLAG] /path/to/image    Set login screen wallpaper'
    echo '    Flags:'
    echo '      --css 'css data'                       Replace css params inside #lockDialogGroup block. Ex: background-size: 1920px 1080px;'
    echo '      --resize 0..6 (default: 2)             Use built-in css template for image resize and alignment. Try this option for fix multi monitor issue. Use 0 for disable resize.'
    echo '        0 - background-repeat: repeat;'
    echo '        1 - background-repeat: no-repeat;'
    echo '        2 - background-repeat: no-repeat;background-size: cover;'
    echo '        3 - background-size: 1920px 1080px;'
    echo '        4 - background-size: 1920px 1080px;background-repeat: repeat;'
    echo '        5 - background-position: 0 0;background-size: 1920px 1080px;background-repeat: repeat;'
    echo '        6 - background-repeat: no-repeat;background-size: cover;background-position: center;'
    echo '  set-gdm-wallpaper --uninstall              Remove changes and set original wallpaper (original gresource file)'
    exit 1
fi
if [ "$1" = "--uninstall" ]; then
    # Restore file if current gresource file is modified by this script.
    # If wallpaper-gdm.png text inside gresource file, then this is modified file.
    if grep -q "wallpaper-gdm.png" /usr/share/gnome-shell/gnome-shell-theme.gresource; then
        cp -f /usr/share/gnome-shell/gnome-shell-theme.gresource.backup /usr/share/gnome-shell/gnome-shell-theme.gresource
        echo 'gnome-shell-theme.gresource recovered'
    fi
    exit
fi
image_parameters="background-repeat: no-repeat;background-size: cover;"
if [ "$1" = "--css" ]; then
    image_parameters="$2;"
    shift
    shift
fi
if [ "$1" = "--resize" ]; then
    case "$2" in
    0) image_parameters="background-repeat: repeat;" ;;
    1) image_parameters="background-repeat: no-repeat;" ;;
    2) image_parameters="background-repeat: no-repeat;background-size: cover;" ;;
    3) image_parameters="background-size: 1920px 1080px;" ;;
    4) image_parameters="background-size: 1920px 1080px;background-repeat: repeat;" ;;
    5) image_parameters="background-position: 0 0;background-size: 1920px 1080px;background-repeat: repeat;" ;;
    6) image_parameters="background-repeat: no-repeat;background-size: cover;background-position: center;" ;;
    *)
        echo "Error: unknown --resize value"
        exit 1
        ;;
    esac
    shift
    shift
fi
if [ "$#" -ne "1" ]; then
    echo "Error: Illegal argument $1"
    exit 1
fi
image="$(realpath "$1")"
if [ ! -f "$image" ]; then
    echo "File not found: \"$image\" "
    exit 1
fi
echo "Updating wallpaper..."
# Restore gresource from backup if current gresource is modified
if grep -q "wallpaper-gdm.png" /usr/share/gnome-shell/gnome-shell-theme.gresource; then
    cp -f /usr/share/gnome-shell/gnome-shell-theme.gresource.backup /usr/share/gnome-shell/gnome-shell-theme.gresource
fi
workdir=$(mktemp -d)
cd "$workdir"
# Creating gnome-shell-theme.gresource.xml with theme file list and add header
echo '<?xml version="1.0" encoding="UTF-8"?>' >"$workdir/gnome-shell-theme.gresource.xml"
echo '<gresources><gresource>' >>"$workdir/gnome-shell-theme.gresource.xml"
for res_file in "$(gresource list /usr/share/gnome-shell/gnome-shell-theme.gresource)"; do
    # create dir for theme file inside temp dir
    mkdir -p "$(dirname "$workdir$res_file")"
    if [ "$res_file" != "/org/gnome/shell/theme/wallpaper-gdm.png" ]; then
        # extract file ($res_file) from current theme and write it to temp dir ($workdir)
        gresource extract /usr/share/gnome-shell/gnome-shell-theme.gresource "$res_file" >"$workdir$res_file"
        # add extracted file name to gnome-shell-theme.gresource.xml
        echo "<file>${res_file#\/}</file>" >>"$workdir/gnome-shell-theme.gresource.xml"
    fi
done
# add our image ($image) to theme path and to xml file
echo "<file>org/gnome/shell/theme/wallpaper-gdm.png</file>" >>"$workdir/gnome-shell-theme.gresource.xml"
cp -f "$image" "$workdir/org/gnome/shell/theme/wallpaper-gdm.png"
# add footer to xml file
echo '</gresource></gresources>' >>"$workdir/gnome-shell-theme.gresource.xml"
# find #lockDialogGroup block inside gnome-shell.css and replace with new_theme_params with our image
# and add image_parameters
new_theme_params="background: #2e3436 url(resource:\/\/\/org\/gnome\/shell\/theme\/wallpaper-gdm.png);$image_parameters"
sed -i -z -E "s/#lockDialogGroup \{[^}]+/#lockDialogGroup \{$new_theme_params/g" "$workdir/org/gnome/shell/theme/gnome-shell.css"

# fix gdm 44
echo '
.login-dialog {
background-color: transparent;
}
' >>"$workdir/org/gnome/shell/theme/gnome-shell.css"

# create gresource file with file list inside gnome-shell-theme.gresource.xml
glib-compile-resources "$workdir/gnome-shell-theme.gresource.xml"
