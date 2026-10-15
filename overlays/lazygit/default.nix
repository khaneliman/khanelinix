_: _final: prev: {
  lazygit = prev.lazygit.overrideAttrs (old: {
    # Ctrl+X clears only the focused commit field, including multiline bodies.
    patches = (old.patches or [ ]) ++ [ ./clear-commit-field.patch ];
    preCheck = (old.preCheck or "") + ''
      go test ./pkg/gui -run 'Test(ClearCommitField|CommitFieldLineEditing)'
    '';
  });
}
