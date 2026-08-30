_: _final: prev: {
  font-manager = prev.font-manager.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace \
        src/font-manager/Collections.vala \
        src/font-manager/FontList.vala \
        --replace-fail \
          '(Gtk.DragIcon) Gtk.DragIcon.get_for_drag(drag)' \
          '(Gtk.DragIcon) new Gtk.DragIcon.get_for_drag(drag)'
    '';
  });
}
