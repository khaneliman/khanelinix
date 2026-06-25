{
  config,
  lib,
  pkgs,
  ...
}:
let
  syncedCalendarAccounts = lib.filterAttrs (
    _name: account: (account.khal.enable or false) && (account.vdirsyncer.enable or false)
  ) (config.accounts.calendar.accounts or { });
  primaryCalendar = config.khanelinix.user.email or null;
  primaryCalendarLabel =
    if primaryCalendar == null then
      { }
    else
      {
        ${primaryCalendar} = "Personal";
      };
  calendarLabelMap =
    primaryCalendarLabel
    // lib.mapAttrs (
      name: account:
      let
        rawUrl = account.remote.url or null;
        rawUserName = account.remote.userName or null;
        url = if rawUrl == null then "" else rawUrl;
        userName = if rawUserName == null then name else rawUserName;
      in
      if lib.hasPrefix "http://localhost:1080/users/" url then
        "Work"
      else if primaryCalendar != null && userName == primaryCalendar then
        "Personal"
      else
        userName
    ) syncedCalendarAccounts;
  calendarLabelMapPython = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: value: "    ${builtins.toJSON name}: ${builtins.toJSON value},"
    ) calendarLabelMap
  );

  calendarHelper = pkgs.writers.writePython3Bin "waybar-calendar-helper" { } ''
    import datetime
    import html
    import json
    import subprocess
    import sys

    KHAL = "${lib.getExe' pkgs.khal "khal"}"
    CALENDAR_LABELS = {
    ${calendarLabelMapPython}
    }
    LOOKAHEAD = "7d"
    MAX_EVENTS = 18
    TIME_WIDTH = 13
    BADGE_WIDTH = 4
    TITLE_WIDTH = 44


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
        value = (
            event.get("start-end-time-style")
            or event.get("start-time")
            or "Time set"
        )
        return compact_time(value)


    def compact_time(value):
        if "-" not in value:
            return compact_time_part(value)

        start, end = [
            compact_time_part(part)
            for part in value.split("-", 1)
        ]
        start_suffix = start[-1:] if start else ""
        end_suffix = end[-1:] if end else ""

        if start_suffix in ["a", "p"] and start_suffix == end_suffix:
            start = start[:-1]

        return f"{start}-{end}"


    def compact_time_part(value):
        value = value.strip()
        try:
            parsed = datetime.datetime.strptime(value, "%I:%M %p")
        except ValueError:
            return value[1:] if value.startswith("0") else value

        hour = parsed.strftime("%I").lstrip("0")
        minute = "" if parsed.minute == 0 else f":{parsed.minute:02d}"
        suffix = parsed.strftime("%p").lower()[:1]
        return f"{hour}{minute}{suffix}"


    def event_calendar(event):
        calendar = event.get("calendar")
        if not calendar:
            return None
        return CALENDAR_LABELS.get(calendar, calendar)


    def event_location(event):
        location = event.get("location")
        if not location:
            return None
        if "microsoft teams" in location.lower():
            return "Teams"
        return location


    def event_badge(event):
        calendar = event_calendar(event)
        location = event_location(event)
        details = []

        if calendar == "Personal":
            details.append("")
        elif calendar == "Work":
            details.append("")
        elif calendar:
            details.append(calendar[:3])

        if location == "Teams":
            details.append("")
        elif location:
            details.append("")

        return " ".join(details)


    def truncate(value, width):
        if len(value) <= width:
            return value
        if width <= 3:
            return value[:width]
        return value[: width - 3].rstrip() + "..."


    def sorted_events(events):
        return sorted(
            events,
            key=lambda event: (
                event.get("all-day") != "True",
                time_sort_value(event),
                end_time_sort_value(event),
                event.get("title") or "",
            ),
        )


    def time_sort_value(event):
        value = event.get("start-time") or ""
        if not value:
            return (0, 0)
        try:
            parsed = datetime.datetime.strptime(value, "%I:%M %p")
        except ValueError:
            return (99, 99)
        return (parsed.hour, parsed.minute)


    def end_time_sort_value(event):
        value = event.get("start-end-time-style") or ""
        if "-" not in value:
            return time_sort_value(event)
        return time_sort_from_text(value.split("-", 1)[1])


    def time_sort_from_text(value):
        try:
            parsed = datetime.datetime.strptime(value.strip(), "%I:%M %p")
        except ValueError:
            return (99, 99)
        return (parsed.hour, parsed.minute)


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
        rendered = 0
        omitted = 0
        for start_date in sorted(grouped):
            day = datetime.date.fromisoformat(start_date)
            if lines:
                lines.append("")
            lines.append(f"<b>{html.escape(day_label(day))}</b>")

            for event in sorted_events(grouped[start_date]):
                if rendered >= MAX_EVENTS:
                    omitted += 1
                    continue

                title = truncate(event.get("title") or "(untitled)", TITLE_WIDTH)
                time = event_time(event).ljust(TIME_WIDTH)
                badge = event_badge(event).ljust(BADGE_WIDTH)
                lines.append(
                    "  "
                    f"<span color='#e0af68'>{html.escape(time)}</span>"
                    f" <small>{html.escape(badge)}</small>"
                    f" {html.escape(title)}"
                )
                rendered += 1

        if omitted:
            lines.append("")
            lines.append(f"<small>+ {omitted} more</small>")

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
