reduce ($managed[0] | to_entries[]) as $provider
  (. ;
    if .providerInstances[$provider.key].driver == $provider.key
      and (.providerInstances[$provider.key].config | type) == "object"
    then
      .providerInstances[$provider.key].config *= $provider.value
      | if $provider.value | has("enabled") then
          .providerInstances[$provider.key].enabled = $provider.value.enabled
        else
          .
        end
    else
      .
    end
  )
