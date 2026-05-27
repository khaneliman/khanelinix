_: {
  # Fires when Claude finishes a response turn and hands control back. Ring the
  # terminal bell on the controlling tty so kitty (directly, or via tmux/zellij
  # bell-forwarding) flags the tab as waiting on your input.
  Stop = [
    {
      matcher = "";
      hooks = [
        {
          type = "command";
          command = ''printf '\a' > /dev/tty 2>/dev/null || true'';
        }
      ];
    }
  ];
}
