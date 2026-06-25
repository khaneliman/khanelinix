{
  config,
  lib,
  pkgs,
  ...
}:
let
  calendarNameMap = lib.mapAttrs (_name: account: account.remote.userName) (
    lib.filterAttrs (
      _name: account:
      (account.khal.enable or false)
      && (account.vdirsyncer.enable or false)
      && (account.remote.userName or null) != null
    ) (config.accounts.calendar.accounts or { })
  );
  calendarNameMapPython = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: value: "    ${builtins.toJSON name}: ${builtins.toJSON value},"
    ) calendarNameMap
  );

  calendarHelper = pkgs.writers.writePython3Bin "waybar-calendar-helper" { } ''
    import datetime
    import html
    import json
    import subprocess
    import sys

    KHAL = "${lib.getExe' pkgs.khal "khal"}"
    CALENDAR_NAMES = {
    ${calendarNameMapPython}
    }
    LOOKAHEAD = "7d"


    def clock_text():
        now = datetime.datetime.now().astimezone()
        return now.strftime("󰃭 %a %d %b  \n󰅐 %I:%M %p %Z")


    def emit(tooltip, css_class):
        print(
            json.dumps(
                {
                    "text": clock_text(),
                    "tooltip": tooltip,
                    "class": css_class,
                },
                ensure_ascii=False,
            )
        )


    def parse_khal_output(output):
        events = []
        for line in output.splitlines():
            line = line.strip()
            if not line:
                continue

            data = json.loads(line)
            if isinstance(data, list):
                events.extend(event for event in data if isinstance(event, dict))

        return events


    def day_label(day):
        today = datetime.date.today()
        if day == today:
            return "Today"
        if day == today + datetime.timedelta(days=1):
            return "Tomorrow"
        return f"{day:%a} {day:%b} {day.day}"


    def event_time(event):
        if event.get("all-day") == "True":
            return "All day"
        return (
            event.get("start-end-time-style")
            or event.get("start-time")
            or "Time set"
        )


    def event_calendar(event):
        calendar = event.get("calendar")
        if not calendar:
            return None
        return CALENDAR_NAMES.get(calendar, calendar)


    def tooltip_for(events):
        if not events:
            return "No events in next 7 days"

        grouped = {}
        for event in events:
            start_date = event.get("start-date")
            if not start_date:
                continue
            grouped.setdefault(start_date, []).append(event)

        if not grouped:
            return "No events in next 7 days"

        lines = []
        for start_date in sorted(grouped):
            day = datetime.date.fromisoformat(start_date)
            if lines:
                lines.append("")
            lines.append(f"<b>{html.escape(day_label(day))}</b>")

            for event in grouped[start_date]:
                title = event.get("title") or "(untitled)"
                time = html.escape(event_time(event))
                lines.append(
                    f"  <span color='#e0af68'>{time}</span> {html.escape(title)}"
                )

                details = [
                    value
                    for value in [
                        event_calendar(event),
                        event.get("location"),
                    ]
                    if value
                ]
                if details:
                    detail = html.escape(" - ".join(details))
                    lines.append(f"    <small>{detail}</small>")

        return "\n".join(lines)


    def main():
        command = [
            KHAL,
            "list",
            "--json",
            "start-date",
            "--json",
            "start-time",
            "--json",
            "start-end-time-style",
            "--json",
            "title",
            "--json",
            "calendar",
            "--json",
            "location",
            "--json",
            "all-day",
            "now",
            LOOKAHEAD,
        ]

        try:
            result = subprocess.run(
                command,
                check=False,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=10,
            )
        except Exception as error:
            emit(f"Calendar unavailable\n{html.escape(str(error))}", "sync-error")
            return 0

        if result.returncode != 0:
            message = (
                result.stderr.strip()
                or result.stdout.strip()
                or "khal failed"
            )
            emit(f"Calendar unavailable\n{html.escape(message)}", "sync-error")
            return 0

        try:
            events = parse_khal_output(result.stdout)
        except Exception as error:
            emit(f"Calendar parse failed\n{html.escape(str(error))}", "sync-error")
            return 0

        emit(tooltip_for(events), "has-events" if events else "no-events")
        return 0


    sys.exit(main())
  '';
in
{
  package = calendarHelper;

  module = {
    "custom/calendar" = {
      exec = lib.getExe calendarHelper;
      return-type = "json";
      format = "{}";
      interval = 60;
      tooltip = true;
      escape = false;
    };
  };
}
