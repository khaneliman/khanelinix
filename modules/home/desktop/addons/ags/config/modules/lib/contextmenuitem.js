const { Gdk, Gtk } = imports.gi;
import { Widget } from '../../imports.js';

export const ContextMenuItem = ({ label, onClick }) => Widget({
    type: Gtk.MenuItem,
    label: `${label}`,
    setup: menuItem => {
        menuItem.connect("activate", onClick);
    }
})