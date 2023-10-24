const { Gdk, Gtk } = imports.gi;
const GObject = imports.gi.GObject;
const Lang = imports.lang;
import { Utils } from '../../imports.js';
const { execAsync, exec } = Utils;

// min-height for diameter
// min-width for trough stroke
// padding for space between trough and progress
// margin for space between widget and parent
// background-color for trough color
// color for progress color
// font size for progress value (0-100px)
// TODO: border-radius for rounded ends (unimportant)
export const CircularProgress = new GObject.Class({
    Name: 'CircularProgressBar',
    GTypeName: 'CircularProgressBar',
    Extends: Gtk.DrawingArea,

    _init: function () {
        this.parent();
        this._progress = 100.0;
        this.connect('draw', Lang.bind(this, this._onDraw));
    },

    setProgress: function (progress) { // TODO: maybe just use a css property and see if it transitions smoothly
        this._progress = progress;
        this.queue_draw();
    },

    _onDraw: function (area, cr) {
        const styleContext = area.get_style_context();
        const width = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
        const height = styleContext.get_property('min-height', Gtk.StateFlags.NORMAL);
        const padding = styleContext.get_padding(Gtk.StateFlags.NORMAL).left;
        const marginLeft = styleContext.get_margin(Gtk.StateFlags.NORMAL).left;
        const marginRight = styleContext.get_margin(Gtk.StateFlags.NORMAL).right;
        const marginTop = styleContext.get_margin(Gtk.StateFlags.NORMAL).top;
        const marginBottom = styleContext.get_margin(Gtk.StateFlags.NORMAL).bottom;
        this._progress = styleContext.get_property('font-size', Gtk.StateFlags.NORMAL) / 100.0;

        const bg_stroke = styleContext.get_property('min-width', Gtk.StateFlags.NORMAL);
        const fg_stroke = bg_stroke - padding;
        const radius = Math.min(width, height) / 2.0 - Math.max(bg_stroke, fg_stroke) / 2.0;
        const center_x = width / 2.0 + marginLeft;
        const center_y = height / 2.0 + marginTop;
        const start_angle = -Math.PI / 2.0;
        const end_angle = start_angle + (2 * Math.PI * this._progress);
        const start_x = center_x + Math.cos(start_angle) * radius;
        const start_y = center_y + Math.sin(start_angle) * radius;
        const end_x = center_x + Math.cos(end_angle) * radius;
        const end_y = center_y + Math.sin(end_angle) * radius;

        area.set_size_request(width + marginLeft + marginRight, height + marginTop + marginBottom);

        // Draw background
        const background_color = styleContext.get_property('background-color', Gtk.StateFlags.NORMAL);
        cr.setSourceRGBA(background_color.red, background_color.green, background_color.blue, background_color.alpha);
        cr.arc(center_x, center_y, radius, 0, 2 * Math.PI);
        cr.setLineWidth(bg_stroke);
        cr.stroke();

        // Draw progress
        const color = styleContext.get_property('color', Gtk.StateFlags.NORMAL);
        cr.setSourceRGBA(color.red, color.green, color.blue, color.alpha);
        cr.arc(center_x, center_y, radius, start_angle, end_angle);
        cr.setLineWidth(fg_stroke);
        cr.stroke();

        // Draw rounded ends for progress arcs
        cr.setLineWidth(0);
        cr.arc(start_x, start_y, fg_stroke / 2, 0, 0 - 0.01);
        cr.fill();
        cr.arc(end_x, end_y, fg_stroke / 2, 0, 0 - 0.01);
        cr.fill();
    }
});

